# Lab: MFA với TOTP (Google Authenticator / Authy)

## Objectives
- Implement TOTP (Time-based One-Time Password) enrollment flow
- Generate QR code cho authenticator apps
- Verify 6-digit TOTP code với drift tolerance
- Tạo và quản lý recovery codes
- Step-up authentication: password → MFA challenge
- "Remember this device" để tránh nhập code mỗi lần

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`
- Lab: `lab-jwt-refresh-token-rotation`

## Tasks

### Task 1: Cài đặt packages
```bash
dotnet add package Otp.NET
dotnet add package QRCoder
```

### Task 2: Hiểu TOTP
```
TOTP (RFC 6238):
- Dựa trên HOTP (HMAC-based OTP) với time counter
- secret_key + floor(current_time / 30) → HMAC-SHA1 → 6-digit code
- Code valid trong 30 giây
- "Drift tolerance": server accept codes ±1 window (±30s)

Setup:
1. Server generate secret key (base32 encoded, ~20 bytes)
2. Show QR code: otpauth://totp/Issuer:user@email?secret=BASE32SECRET&issuer=AppName
3. User scan với Google Authenticator
4. User verify với first code → MFA enabled
```

### Task 3: Generate TOTP secret và QR code
```csharp
public class MfaService
{
    public TotpSetupResult GenerateSetup(string userEmail)
    {
        // Generate random secret (20 bytes, base32 encoded)
        var secretBytes = new byte[20];
        RandomNumberGenerator.Fill(secretBytes);
        var secretBase32 = Base32Encoding.ToString(secretBytes);

        // Build OTP URI
        var issuer = "OrdersApp";
        var otpUri = $"otpauth://totp/{Uri.EscapeDataString(issuer)}:{Uri.EscapeDataString(userEmail)}" +
                     $"?secret={secretBase32}&issuer={Uri.EscapeDataString(issuer)}&algorithm=SHA1&digits=6&period=30";

        // Generate QR code as PNG
        using var qrGenerator = new QRCodeGenerator();
        var qrData = qrGenerator.CreateQrCode(otpUri, QRCodeGenerator.ECCLevel.M);
        using var qrCode = new PngByteQRCode(qrData);
        var qrPng = qrCode.GetGraphic(10);

        return new TotpSetupResult
        {
            SecretKey = secretBase32,
            QrCodeBase64 = Convert.ToBase64String(qrPng),
            ManualEntryKey = FormatKeyForDisplay(secretBase32) // "JBSW Y3DP EHPK 3PXP"
        };
    }

    private static string FormatKeyForDisplay(string key)
        => string.Join(" ", Enumerable.Range(0, key.Length / 4)
                                      .Select(i => key.Substring(i * 4, 4)));
}
```

### Task 4: Verify TOTP code
```csharp
public bool VerifyCode(string secretBase32, string userCode, bool allowDrift = true)
{
    if (!long.TryParse(userCode, out _) || userCode.Length != 6)
        return false;

    var totp = new Totp(Base32Encoding.ToBytes(secretBase32));

    // Verify với drift tolerance (±1 window = ±30 seconds)
    return totp.VerifyTotp(
        userCode,
        out _,
        window: allowDrift ? VerificationWindow.RfcSpecifiedNetworkDelay : null);
}
```

### Task 5: MFA enrollment flow
```csharp
// Step 1: Generate setup info
app.MapPost("/mfa/setup/start", async (
    UserManager<ApplicationUser> userManager, ClaimsPrincipal user) =>
{
    var appUser = await userManager.GetUserAsync(user);
    if (appUser!.TwoFactorEnabled)
        return Results.Conflict("MFA already enabled");

    var setup = _mfaService.GenerateSetup(appUser.Email!);

    // Store secret temporarily (user hasn't verified yet)
    await userManager.SetAuthenticationTokenAsync(
        appUser, "MFA", "TOTP_TEMP_SECRET", setup.SecretKey);

    return Results.Ok(new
    {
        QrCode = $"data:image/png;base64,{setup.QrCodeBase64}",
        ManualKey = setup.ManualEntryKey
    });
}).RequireAuthorization();

// Step 2: Verify first code → activate MFA
app.MapPost("/mfa/setup/verify", async (
    VerifyMfaRequest request,
    UserManager<ApplicationUser> userManager, ClaimsPrincipal user) =>
{
    var appUser = await userManager.GetUserAsync(user);
    var tempSecret = await userManager.GetAuthenticationTokenAsync(
        appUser!, "MFA", "TOTP_TEMP_SECRET");

    if (tempSecret == null)
        return Results.BadRequest("Setup not started");

    if (!_mfaService.VerifyCode(tempSecret, request.Code))
        return Results.BadRequest("Invalid code. Make sure your device time is correct.");

    // Activate: move temp secret to permanent
    await userManager.RemoveAuthenticationTokenAsync(appUser!, "MFA", "TOTP_TEMP_SECRET");
    await userManager.SetAuthenticationTokenAsync(appUser!, "MFA", "TOTP_SECRET", tempSecret);
    await userManager.SetTwoFactorEnabledAsync(appUser!, true);

    // Generate recovery codes
    var recoveryCodes = await GenerateRecoveryCodesAsync(appUser!);

    return Results.Ok(new
    {
        Message = "MFA enabled successfully!",
        RecoveryCodes = recoveryCodes,  // Show ONCE
        Warning = "Save these codes securely. Each can only be used once."
    });
}).RequireAuthorization();
```

### Task 6: Recovery codes
```csharp
public async Task<string[]> GenerateRecoveryCodesAsync(ApplicationUser user)
{
    var codes = Enumerable.Range(0, 8)
        .Select(_ => GenerateRecoveryCode())
        .ToArray();

    // Store hashed codes
    var hashedCodes = codes
        .Select(c => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(c))))
        .ToList();

    await _db.RecoveryCodes.Where(r => r.UserId == user.Id).ExecuteDeleteAsync();
    _db.RecoveryCodes.AddRange(hashedCodes.Select(hash => new RecoveryCode
    {
        UserId = user.Id,
        CodeHash = hash
    }));
    await _db.SaveChangesAsync();

    return codes;  // Return raw codes — stored only as hashes
}

private static string GenerateRecoveryCode()
{
    // Format: XXXXX-XXXXX (10 alphanumeric chars)
    const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // No ambiguous chars
    var bytes = RandomNumberGenerator.GetBytes(10);
    var code = new string(bytes.Select(b => chars[b % chars.Length]).ToArray());
    return $"{code[..5]}-{code[5..]}";
}

// Use recovery code:
app.MapPost("/auth/mfa/recover", async (RecoverRequest request, ...) =>
{
    var codeHash = Convert.ToHexString(
        SHA256.HashData(Encoding.UTF8.GetBytes(request.RecoveryCode.Replace("-", "").ToUpper())));

    var recoveryCode = await _db.RecoveryCodes
        .FirstOrDefaultAsync(r => r.UserId == userId && r.CodeHash == codeHash && !r.IsUsed);

    if (recoveryCode == null)
        return Results.Unauthorized();

    // Mark as used — one-time only
    recoveryCode.IsUsed = true;
    await _db.SaveChangesAsync();

    // Issue session
    var token = await IssueTokenAsync(user);
    return Results.Ok(new { Token = token });
});
```

### Task 7: Step-up auth flow
```csharp
// Login: bước 1 — validate password
app.MapPost("/auth/login", async (LoginRequest request, ...) =>
{
    var user = await AuthenticateWithPasswordAsync(request);
    if (user == null) return Results.Unauthorized();

    if (!user.TwoFactorEnabled)
    {
        // No MFA → issue full token
        return Results.Ok(new { AccessToken = await IssueAccessTokenAsync(user) });
    }

    // Has MFA → issue temporary MFA challenge token
    var mfaToken = GenerateMfaToken(user.Id); // Short-lived, limited claims
    return Results.Ok(new { MfaRequired = true, MfaToken = mfaToken });
});

// Login: bước 2 — verify TOTP
app.MapPost("/auth/mfa/verify", async (MfaVerifyRequest request, ...) =>
{
    var userId = ValidateMfaToken(request.MfaToken);
    var user = await userManager.FindByIdAsync(userId);
    var secret = await userManager.GetAuthenticationTokenAsync(user!, "MFA", "TOTP_SECRET");

    if (!_mfaService.VerifyCode(secret!, request.TotpCode))
        return Results.Unauthorized();

    // Remember device (optional)
    if (request.RememberDevice)
    {
        var deviceToken = GenerateDeviceToken();
        Response.Cookies.Append("remember_device", deviceToken, new CookieOptions
        {
            HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict,
            Expires = DateTimeOffset.UtcNow.AddDays(30)
        });
        await StoreDeviceTokenAsync(user!.Id, deviceToken);
    }

    return Results.Ok(new { AccessToken = await IssueAccessTokenAsync(user!) });
});
```

## Expected Output
- `POST /mfa/setup/start` → QR code PNG (base64) + manual key
- Scan QR với Google Authenticator → 6-digit codes appear
- `POST /mfa/setup/verify` với correct code → MFA enabled + 8 recovery codes
- `POST /auth/login` → `{mfaRequired: true, mfaToken: "..."}`
- `POST /auth/mfa/verify` với correct TOTP → access token
- Recovery code used → 401 on second use
- "Remember device" → no MFA challenge for 30 days on same device

## Key Concepts
- **TOTP**: HMAC(secret, floor(time/30)) → 6 digits; same algorithm both sides
- **Drift tolerance**: accept codes ±1 window for clock skew
- **QR code**: `otpauth://totp/` URI standard, supported by all authenticators
- **Recovery codes**: one-time backup codes, stored hashed, shown once
- **Step-up auth**: first token (password only) → second token (password + MFA)
- **Remember device**: skip MFA for trusted devices; invalidate on logout or security event

## Resources
- [RFC 6238 — TOTP](https://www.rfc-editor.org/rfc/rfc6238)
- [Otp.NET library](https://github.com/kspearrin/Otp.NET)
- [QRCoder library](https://github.com/codebude/QRCoder)
- [ASP.NET Core 2FA](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/2fa)
