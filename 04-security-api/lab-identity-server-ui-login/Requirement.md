# Lab: IdentityServer — Login/Consent UI với Razor Pages

## Objectives
- Scaffold Login, Logout, Consent và Error Razor Pages
- Sử dụng `IIdentityServerInteractionService` để lấy authorization context
- Implement "Remember me" với persistent cookies
- Xây dựng Consent page cho interactive clients
- Custom branding và error handling

## Prerequisites
- Lab: `lab-identity-server-quickstart`
- Lab: `lab-aspnet-core-identity-setup` (nếu dùng ASP.NET Core Identity)

## Tasks

### Task 1: Thêm Razor Pages support
```bash
dotnet add package Duende.IdentityServer.AspNetIdentity  # nếu dùng ASP.NET Identity
# Hoặc chỉ cần:
dotnet add package Microsoft.AspNetCore.Mvc.RazorPages
```

```csharp
builder.Services.AddRazorPages();
app.MapRazorPages();
```

### Task 2: Login Page
```csharp
// Pages/Account/Login.cshtml.cs
public class LoginModel : PageModel
{
    private readonly IIdentityServerInteractionService _interaction;
    private readonly SignInManager<ApplicationUser> _signInManager;

    [BindProperty]
    public LoginInputModel Input { get; set; } = new();
    public string? ReturnUrl { get; set; }
    public bool AllowRememberMe { get; set; } = true;

    public async Task<IActionResult> OnGetAsync(string? returnUrl = null)
    {
        ReturnUrl = returnUrl;

        // Lấy context từ returnUrl — biết client nào đang request login
        var context = await _interaction.GetAuthorizationContextAsync(returnUrl);
        if (context != null)
        {
            // Pre-fill username nếu có IdP hint
            Input.Username = context.LoginHint ?? "";
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(string? returnUrl = null)
    {
        var context = await _interaction.GetAuthorizationContextAsync(returnUrl);

        var result = await _signInManager.PasswordSignInAsync(
            Input.Username,
            Input.Password,
            isPersistent: Input.RememberMe,  // Persistent cookie
            lockoutOnFailure: true);

        if (result.Succeeded)
        {
            if (_interaction.IsValidReturnUrl(returnUrl))
                return Redirect(returnUrl!);
            return Redirect("~/");
        }

        ModelState.AddModelError("", "Invalid username or password");
        return Page();
    }
}

public class LoginInputModel
{
    [Required] public string Username { get; set; } = "";
    [Required] [DataType(DataType.Password)] public string Password { get; set; } = "";
    public bool RememberMe { get; set; }
}
```

```html
<!-- Pages/Account/Login.cshtml -->
<form method="post">
    <div class="form-group">
        <label asp-for="Input.Username">Username</label>
        <input asp-for="Input.Username" class="form-control" autofocus />
        <span asp-validation-for="Input.Username" class="text-danger"></span>
    </div>
    <div class="form-group">
        <label asp-for="Input.Password">Password</label>
        <input asp-for="Input.Password" class="form-control" />
    </div>
    <div class="form-check">
        <input asp-for="Input.RememberMe" class="form-check-input" />
        <label asp-for="Input.RememberMe">Remember me</label>
    </div>
    <button type="submit" class="btn btn-primary">Login</button>
</form>
```

### Task 3: Logout Page
```csharp
// Pages/Account/Logout.cshtml.cs
public class LogoutModel : PageModel
{
    private readonly IIdentityServerInteractionService _interaction;
    private readonly SignInManager<ApplicationUser> _signInManager;

    public async Task<IActionResult> OnGetAsync(string? logoutId = null)
    {
        // Hiển thị trang xác nhận logout? Hay logout ngay?
        var context = await _interaction.GetLogoutContextAsync(logoutId);

        if (context?.ShowSignoutPrompt == false)
        {
            // Logout ngay — triggered bởi client với valid session
            return await ProcessLogoutAsync(logoutId, context);
        }

        // Hiển thị trang xác nhận
        LogoutId = logoutId;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(string? logoutId = null)
    {
        var context = await _interaction.GetLogoutContextAsync(logoutId);
        return await ProcessLogoutAsync(logoutId, context);
    }

    private async Task<IActionResult> ProcessLogoutAsync(string? logoutId, LogoutRequest? context)
    {
        await _signInManager.SignOutAsync();

        var postLogoutRedirectUri = context?.PostLogoutRedirectUri;
        if (!string.IsNullOrEmpty(postLogoutRedirectUri))
            return Redirect(postLogoutRedirectUri);

        return Page(); // Hiển thị "Logged out" page
    }
}
```

### Task 4: Consent Page
```csharp
// Pages/Consent/Index.cshtml.cs
public class ConsentModel : PageModel
{
    private readonly IIdentityServerInteractionService _interaction;

    public AuthorizationRequest? Request { get; set; }
    public List<ScopeViewModel> Scopes { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(string? returnUrl = null)
    {
        Request = await _interaction.GetAuthorizationContextAsync(returnUrl);
        if (Request == null) return RedirectToPage("/Error");

        // Build scope view models
        Scopes = Request.ValidatedResources.Resources.ApiScopes
            .Select(s => new ScopeViewModel
            {
                Name = s.Name,
                DisplayName = s.DisplayName ?? s.Name,
                Description = s.Description,
                Required = s.Required,
                Checked = true  // Pre-check optional scopes
            }).ToList();

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        string? returnUrl, bool grantConsent, List<string> scopes)
    {
        var request = await _interaction.GetAuthorizationContextAsync(returnUrl);

        ConsentResponse? response = null;
        if (grantConsent)
        {
            response = new ConsentResponse
            {
                RememberConsent = true,
                ScopesValuesConsented = scopes
            };
        }
        else
        {
            response = new ConsentResponse { Error = AuthorizationError.AccessDenied };
        }

        await _interaction.GrantConsentAsync(request!, response);
        return Redirect(returnUrl!);
    }
}
```

```html
<!-- Pages/Consent/Index.cshtml -->
<h2>@Model.Request?.Client.ClientName requests access</h2>

<form method="post">
    <h4>Allow access to:</h4>
    @foreach (var scope in Model.Scopes)
    {
        <div class="form-check">
            <input type="checkbox" name="scopes" value="@scope.Name"
                   checked="@scope.Checked" @(scope.Required ? "disabled" : "") />
            <label>@scope.DisplayName</label>
            <small class="text-muted">@scope.Description</small>
        </div>
    }

    <button type="submit" name="grantConsent" value="true" class="btn btn-primary">Allow</button>
    <button type="submit" name="grantConsent" value="false" class="btn btn-secondary">Deny</button>
</form>
```

### Task 5: Error Page
```csharp
// Pages/Error/Index.cshtml.cs
public class ErrorModel : PageModel
{
    private readonly IIdentityServerInteractionService _interaction;

    public string? ErrorMessage { get; set; }
    public string? ErrorDescription { get; set; }

    public async Task OnGetAsync(string? errorId = null)
    {
        if (errorId != null)
        {
            var message = await _interaction.GetErrorContextAsync(errorId);
            ErrorMessage = message?.Error;
            ErrorDescription = message?.ErrorDescription;
        }
    }
}
```

### Task 6: Custom branding
```css
/* wwwroot/css/identity.css */
:root {
    --primary-color: #0066cc;
    --logo-url: url('/images/logo.png');
}

.login-card {
    max-width: 400px;
    margin: 80px auto;
    padding: 2rem;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.login-logo {
    text-align: center;
    margin-bottom: 2rem;
}
```

### Task 7: Remember me — persistent vs session cookie
```csharp
// Identity cookie options
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;

    // Session cookie (default, expires khi đóng browser):
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = true;

    // Persistent cookie (khi chọn "Remember me"):
    // Controlled by isPersistent: true trong SignInAsync
    options.Cookie.MaxAge = TimeSpan.FromDays(30); // Max age cho persistent
});
```

## Expected Output
- Login page hiển thị với username/password + Remember me
- Sai password → error message, lockout sau 5 lần
- Consent page hiển thị scopes với Allow/Deny buttons
- Deny consent → redirect về client với `error=access_denied`
- Allow consent → redirect về client với authorization code
- Remember me → cookie tồn tại sau khi đóng browser

## Key Concepts
- **IIdentityServerInteractionService**: lấy context (client info, scopes requested) từ returnUrl
- **AuthorizationRequest**: thông tin về client đang request auth
- **ConsentResponse**: user's decision + selected scopes
- **ShowSignoutPrompt**: IdentityServer hint về có nên hỏi confirm logout không
- **Persistent cookie**: `isPersistent: true` → `Max-Age` set trong cookie
- **Session cookie**: không có `Max-Age` → browser xóa khi close

## Resources
- [Duende — login UI quickstart](https://docs.duendesoftware.com/identityserver/v7/quickstarts/2_interactive/)
- [Duende — IIdentityServerInteractionService](https://docs.duendesoftware.com/identityserver/v7/reference/services/interaction/)
- [Duende — consent](https://docs.duendesoftware.com/identityserver/v7/ui/consent/)
