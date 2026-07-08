# Lab: OAuth2 — Device Code Flow (CLI / IoT)

## Objectives
- Implement Device Code flow cho CLI tools và IoT devices
- Hiểu polling mechanism và error handling
- Build một CLI tool thực sự authenticate với IdentityServer
- Demo với Azure AD Device Code flow
- Handle các trạng thái: pending, slow_down, expired, denied

## Prerequisites
- Lab: `lab-identity-server-quickstart`
- Azure subscription (cho Task 6 — Azure AD demo)

## Tasks

### Task 1: Tại sao cần Device Code flow?
```
Standard flows yêu cầu:
- Authorization Code: browser redirect
- Client Credentials: client secret (không phải cho end users)

Device Code giải quyết:
- Smart TV, gaming console, CLI tools, IoT devices
- Không có browser hoặc không tiện nhập URL dài
- User dùng phone/laptop khác để authorize

Flow:
1. Device → POST /deviceauthorization → nhận device_code, user_code, verification_uri
2. Device hiển thị: "Go to https://example.com/device and enter code: ABCD-WXYZ"
3. Device poll /token với device_code (mỗi 5 giây)
4. User mở browser, nhập user_code, login, authorize
5. Polling → thành công → nhận tokens
```

### Task 2: IdentityServer — bật Device flow
```csharp
// Config.cs
new Client
{
    ClientId = "orders-cli",
    ClientName = "Orders CLI Tool",
    AllowedGrantTypes = GrantTypes.DeviceFlow,
    RequireClientSecret = false,  // Public client
    AllowedScopes = { "openid", "profile", "email", "orders:read" },
    DeviceCodeLifetime = 300,  // 5 phút để user authorize
    PollingInterval = 5        // Minimum 5 giây giữa các polling
}
```

### Task 3: Step 1 — Request device authorization
```csharp
public async Task<DeviceAuthorizationResponse> RequestDeviceCodeAsync()
{
    var disco = await new DiscoveryDocumentRequest
    {
        Address = "https://localhost:5001"
    }.GetDiscoveryDocumentAsync(new HttpClient());

    var response = await new HttpClient().RequestDeviceAuthorizationAsync(
        new DeviceAuthorizationRequest
        {
            Address = disco.DeviceAuthorizationEndpoint,
            ClientId = "orders-cli",
            Scope = "openid profile email orders:read"
        });

    if (response.IsError)
        throw new InvalidOperationException(response.Error);

    return response;
}
```

### Task 4: Display instructions to user
```csharp
public static void DisplayLoginInstructions(DeviceAuthorizationResponse auth)
{
    Console.Clear();
    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.WriteLine("╔══════════════════════════════════════╗");
    Console.WriteLine("║       ORDERS CLI — Authentication    ║");
    Console.WriteLine("╚══════════════════════════════════════╝");
    Console.ResetColor();
    Console.WriteLine();
    Console.WriteLine("To sign in:");
    Console.WriteLine();
    Console.ForegroundColor = ConsoleColor.Yellow;
    Console.WriteLine($"  1. Open: {auth.VerificationUri}");
    Console.WriteLine($"  2. Enter code: {auth.UserCode}");
    Console.ResetColor();
    Console.WriteLine();
    Console.WriteLine($"This code expires in {auth.ExpiresIn} seconds.");
    Console.WriteLine("Waiting for authentication...");

    // Try to open browser automatically
    try { Process.Start(new ProcessStartInfo(auth.VerificationUriComplete!) { UseShellExecute = true }); }
    catch { /* ignore — some environments can't open browser */ }
}
```

### Task 5: Step 2 — Poll for token
```csharp
public async Task<TokenResponse> WaitForTokenAsync(DeviceAuthorizationResponse auth)
{
    var pollingInterval = auth.Interval > 0 ? auth.Interval : 5;
    var expiresAt = DateTime.UtcNow.AddSeconds(auth.ExpiresIn);

    while (DateTime.UtcNow < expiresAt)
    {
        await Task.Delay(TimeSpan.FromSeconds(pollingInterval));

        var tokenResponse = await new HttpClient().RequestDeviceTokenAsync(
            new DeviceTokenRequest
            {
                Address = "https://localhost:5001/connect/token",
                ClientId = "orders-cli",
                DeviceCode = auth.DeviceCode
            });

        // Handle errors
        switch (tokenResponse.Error)
        {
            case OidcConstants.TokenErrors.AuthorizationPending:
                // User hasn't authorized yet — keep polling
                Console.Write(".");
                continue;

            case OidcConstants.TokenErrors.SlowDown:
                // IdentityServer bảo poll chậm hơn
                pollingInterval += 5;
                Console.WriteLine($"\n[Slow down — polling every {pollingInterval}s]");
                continue;

            case OidcConstants.TokenErrors.ExpiredToken:
                throw new TimeoutException("Authentication timed out. Please try again.");

            case OidcConstants.TokenErrors.AccessDenied:
                throw new UnauthorizedAccessException("User denied access.");

            case null when !tokenResponse.IsError:
                // Success!
                Console.WriteLine("\n✓ Authentication successful!");
                return tokenResponse;

            default:
                throw new InvalidOperationException($"Token error: {tokenResponse.Error}");
        }
    }

    throw new TimeoutException("Device code expired.");
}
```

### Task 6: Full CLI tool
```csharp
public class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("Orders CLI v1.0");
        Console.WriteLine("Authenticating...");

        try
        {
            var service = new DeviceCodeAuthService();
            var auth = await service.RequestDeviceCodeAsync();
            DisplayLoginInstructions(auth);

            var tokens = await service.WaitForTokenAsync(auth);

            // Save tokens securely (OS keychain / encrypted file)
            TokenStorage.Save(tokens);

            Console.WriteLine($"Welcome! Access token expires in {tokens.ExpiresIn}s");
            Console.WriteLine("You can now use the CLI.");

            // Run CLI commands with token
            await RunCliAsync(tokens.AccessToken!);
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"Error: {ex.Message}");
            Console.ResetColor();
            Environment.Exit(1);
        }
    }
}
```

### Task 7: Demo với Azure AD Device Code
```csharp
// Thay IdentityServer bằng Azure AD
var pca = PublicClientApplicationBuilder
    .Create("{app-registration-client-id}")
    .WithAuthority(AzureCloudInstance.AzurePublic, "{tenant-id}")
    .Build();

var result = await pca
    .AcquireTokenWithDeviceCode(
        new[] { "https://graph.microsoft.com/.default" },
        deviceCodeCallback =>
        {
            Console.WriteLine(deviceCodeCallback.Message);
            return Task.CompletedTask;
        })
    .ExecuteAsync();

Console.WriteLine($"Hello {result.Account.Username}!");
// Dùng result.AccessToken để gọi Microsoft Graph
```

## Expected Output
```
Orders CLI v1.0
Authenticating...

╔══════════════════════════════════════╗
║       ORDERS CLI — Authentication    ║
╚══════════════════════════════════════╝

To sign in:

  1. Open: https://localhost:5001/device
  2. Enter code: WXYZ-ABCD

This code expires in 300 seconds.
Waiting for authentication......

✓ Authentication successful!
Welcome, Alice! Access token expires in 3600s.

> orders list
  [1] Order #001 - $99.99
  [2] Order #002 - $149.50
```

## Key Concepts
- **Device Code**: single-use, short-lived code for the device
- **User Code**: human-friendly 8-char code displayed to user
- **Polling**: device checks every N seconds (N ≥ interval from server)
- **slow_down**: server requesting device to reduce polling rate
- **VerificationUriComplete**: URL with user_code pre-filled (for QR codes)
- **Public client**: no client secret — appropriate for native apps and CLIs

## Resources
- [RFC 8628 — Device Authorization Grant](https://www.rfc-editor.org/rfc/rfc8628)
- [Duende — device flow](https://docs.duendesoftware.com/identityserver/v7/ui/device_flow/)
- [MSAL Device Code — Azure AD](https://learn.microsoft.com/en-us/entra/identity-platform/scenario-desktop-acquire-token-device-code-flow)
