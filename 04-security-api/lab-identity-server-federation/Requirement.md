# Lab: IdentityServer — External IdP Federation (Google/GitHub)

## Objectives
- Cấu hình Google và GitHub làm external authentication providers
- Auto-provision local user từ external claims
- Implement account linking (external login → existing account)
- Claims mapping từ external IdP → local IdentityUser
- Hiểu security considerations khi federate với external IdP

## Prerequisites
- Lab: `lab-identity-server-ui-login`
- Lab: `lab-aspnet-core-identity-setup`
- Google Cloud Console account hoặc GitHub OAuth App

## Tasks

### Task 1: Cài đặt external providers
```bash
dotnet add package Microsoft.AspNetCore.Authentication.Google
dotnet add package AspNet.Security.OAuth.GitHub
```

```csharp
// Program.cs — thêm sau AddIdentityServer()
builder.Services.AddAuthentication()
    .AddGoogle("Google", options =>
    {
        options.ClientId = builder.Configuration["Authentication:Google:ClientId"]!;
        options.ClientSecret = builder.Configuration["Authentication:Google:ClientSecret"]!;
        options.Scope.Add("profile");
        options.Scope.Add("email");
    })
    .AddGitHub("GitHub", options =>
    {
        options.ClientId = builder.Configuration["Authentication:GitHub:ClientId"]!;
        options.ClientSecret = builder.Configuration["Authentication:GitHub:ClientSecret"]!;
        options.Scope.Add("user:email");
    });
```

### Task 2: Login page — hiển thị external provider buttons
```html
<!-- Pages/Account/Login.cshtml -->
<div class="external-login-section">
    <h4>Or login with:</h4>
    <a asp-page="/ExternalLogin/Challenge"
       asp-route-provider="Google"
       asp-route-returnUrl="@Model.ReturnUrl"
       class="btn btn-outline-danger">
        🔴 Google
    </a>
    <a asp-page="/ExternalLogin/Challenge"
       asp-route-provider="GitHub"
       asp-route-returnUrl="@Model.ReturnUrl"
       class="btn btn-outline-dark">
        ⚫ GitHub
    </a>
</div>
```

### Task 3: ExternalLogin Challenge handler
```csharp
// Pages/ExternalLogin/Challenge.cshtml.cs
public class ChallengeModel : PageModel
{
    public IActionResult OnGet(string provider, string? returnUrl = null)
    {
        // Redirect đến external provider (Google/GitHub)
        var redirectUrl = Url.Page("/ExternalLogin/Callback",
            values: new { returnUrl });

        var properties = new AuthenticationProperties
        {
            RedirectUri = redirectUrl,
            Items = { { "scheme", provider }, { "returnUrl", returnUrl ?? "/" } }
        };

        return Challenge(properties, provider);
    }
}
```

### Task 4: ExternalLogin Callback — provision user
```csharp
// Pages/ExternalLogin/Callback.cshtml.cs
public class CallbackModel : PageModel
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IIdentityServerInteractionService _interaction;

    public async Task<IActionResult> OnGetAsync(string? returnUrl = null)
    {
        // Lấy external login info (provider + provider key + claims)
        var info = await _signInManager.GetExternalLoginInfoAsync();
        if (info == null) return RedirectToPage("/Account/Login");

        // Thử login với existing external login link
        var result = await _signInManager.ExternalLoginSignInAsync(
            info.LoginProvider, info.ProviderKey, isPersistent: false);

        if (result.Succeeded)
        {
            // Existing user — login thành công
            if (_interaction.IsValidReturnUrl(returnUrl))
                return Redirect(returnUrl!);
            return Redirect("~/");
        }

        // Không có existing link → auto-provision new user
        return await ProvisionUserAsync(info, returnUrl);
    }

    private async Task<IActionResult> ProvisionUserAsync(
        ExternalLoginInfo info, string? returnUrl)
    {
        // Extract claims từ external provider
        var email = info.Principal.FindFirstValue(ClaimTypes.Email)
                    ?? info.Principal.FindFirstValue("email")
                    ?? throw new InvalidOperationException("No email claim");

        var name = info.Principal.FindFirstValue(ClaimTypes.Name)
                   ?? info.Principal.FindFirstValue("name")
                   ?? email;

        // Kiểm tra user đã tồn tại với email này chưa
        var existingUser = await _userManager.FindByEmailAsync(email);
        if (existingUser != null)
        {
            // Account linking: thêm external login vào existing user
            await _userManager.AddLoginAsync(existingUser, info);
            await _signInManager.SignInAsync(existingUser, isPersistent: false);
            return Redirect(returnUrl ?? "~/");
        }

        // Tạo user mới
        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            FullName = name,
            EmailConfirmed = true  // Trust external provider's email verification
        };

        var createResult = await _userManager.CreateAsync(user);
        if (!createResult.Succeeded)
        {
            // Handle error
            return RedirectToPage("/Error");
        }

        // Link external login
        await _userManager.AddLoginAsync(user, info);

        // Add default role
        await _userManager.AddToRoleAsync(user, "User");

        await _signInManager.SignInAsync(user, isPersistent: false);
        return Redirect(returnUrl ?? "~/");
    }
}
```

### Task 5: Claims mapping từ external providers
```csharp
// Google claims:
// "sub" → unique Google user ID
// "email" → email
// "name" → full name
// "given_name", "family_name" → first, last name
// "picture" → profile picture URL

// GitHub claims:
// "NameIdentifier" → numeric GitHub user ID
// "login" → GitHub username
// "email" → email (nếu public hoặc authorized)
// "name" → full name

// Map external claims → local claims trong ClaimsPrincipalFactory
public class ExternalClaimsMappingFactory
{
    public static IEnumerable<Claim> MapFromGoogle(ExternalLoginInfo info)
    {
        yield return new Claim("provider", "Google");
        yield return new Claim("provider_user_id", info.ProviderKey);

        var picture = info.Principal.FindFirstValue("urn:google:picture")
                      ?? info.Principal.FindFirstValue("picture");
        if (picture != null)
            yield return new Claim("picture", picture);
    }
}
```

### Task 6: Security — email trust
```csharp
// NGUY HIỂM: Không nên tự động link nếu chỉ dựa vào email
// Vì: User có thể tạo Google account với email của người khác

// SAFE approach:
// 1. Nếu email đã tồn tại nhưng chưa có external login:
//    → Hỏi user confirm password trước khi link
//    → KHÔNG tự động link

// SAFER approach với email verification:
if (existingUser != null && !existingUser.EmailConfirmed)
{
    // Email chưa verify → không cho link
    return RedirectToPage("/Account/Login",
        new { error = "Please verify your email first" });
}
```

### Task 7: View linked external logins
```csharp
app.MapGet("/account/external-logins", async (
    UserManager<ApplicationUser> userManager,
    ClaimsPrincipal user) =>
{
    var appUser = await userManager.GetUserAsync(user);
    var logins = await userManager.GetLoginsAsync(appUser!);

    return Results.Ok(logins.Select(l => new
    {
        l.LoginProvider,
        l.ProviderDisplayName,
        l.ProviderKey
    }));
}).RequireAuthorization();
```

## Expected Output
- Login page hiển thị "Login with Google" và "Login with GitHub" buttons
- Click Google → redirect đến Google consent → callback → user created in DB
- Second login với same Google account → existing user signed in (no duplicate)
- `/account/external-logins` → list of linked providers
- User có thể link cả Google và GitHub vào cùng một account

## Key Concepts
- **ExternalLoginInfo**: provider name, provider key, external ClaimsPrincipal
- **ExternalLoginSignInAsync**: check if external login already linked
- **AddLoginAsync**: link external login to existing user (AspNetUserLogins table)
- **ProviderKey**: unique ID từ external provider (Google's "sub", GitHub's numeric ID)
- **Email trust risk**: never auto-link purely by email without verification
- **Account federation**: IdentityServer as central IdP, delegates to Google/GitHub

## Resources
- [External OAuth login in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/social/)
- [Google authentication setup](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/social/google-logins)
- [GitHub OAuth app](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)
- [Duende external providers](https://docs.duendesoftware.com/identityserver/v7/ui/login/external/)
