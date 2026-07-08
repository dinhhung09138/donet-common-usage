# Lab: JWT Tokens — Deep Dive (Structure, Algorithms, JWKS)

## Objectives
- Giải mã và hiểu cấu trúc JWT (header.payload.signature)
- So sánh HS256 vs RS256 — khi nào dùng cái nào
- Tạo RSA key pair, sign và validate token
- Expose JWKS endpoint để resource servers tự fetch public key
- Demo và fix các lỗ hổng JWT phổ biến

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`

## Tasks

### Task 1: Giải mã JWT bằng tay
```csharp
// JWT format: base64url(header).base64url(payload).base64url(signature)
var jwt = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFudG9ueSIsImlhdCI6MTUxNjIzOTAyMn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
var parts = jwt.Split('.');

// Decode header
var header = JsonSerializer.Deserialize<JsonElement>(
    Base64UrlDecode(parts[0]));
// {"alg":"RS256","typ":"JWT"}

// Decode payload
var payload = JsonSerializer.Deserialize<JsonElement>(
    Base64UrlDecode(parts[1]));
// {"sub":"1234567890","name":"Antony","iat":1516239022}

// Signature = base64url(sign(header.payload, key))
// Không thể decode signature — đây là hash/signature bytes
```

### Task 2: HS256 vs RS256

| | HS256 | RS256 |
|---|---|---|
| Algorithm | HMAC-SHA256 (symmetric) | RSA-SHA256 (asymmetric) |
| Key | 1 shared secret | Private key (sign) + Public key (verify) |
| Security | Ai có key đều sign được | Chỉ private key sign; public key chỉ verify |
| Use case | Monolith, single service | Microservices, multiple resource servers |
| Key management | Phải share secret với mọi service verify | Chỉ distribute public key |

```
Khi nào dùng RS256:
✓ Multiple resource servers cần verify token
✓ Public key có thể được publish qua JWKS endpoint
✓ Zero-trust: resource server không cần trust auth server hoàn toàn

Khi nào dùng HS256:
✓ Single service (sign + verify cùng process)
✓ Đơn giản, không cần key infrastructure
✗ KHÔNG dùng nếu nhiều services cần verify
```

### Task 3: Tạo RSA key pair và sign với RS256
```csharp
// Tạo RSA key pair
using var rsa = RSA.Create(2048);
var privateKey = rsa.ExportRSAPrivateKey();
var publicKey = rsa.ExportRSAPublicKey();

// Lưu ra file (thực tế dùng Key Vault)
File.WriteAllBytes("private.key", privateKey);
File.WriteAllBytes("public.key", publicKey);

// Sign token
public string GenerateToken(ApplicationUser user)
{
    using var rsa = RSA.Create();
    rsa.ImportRSAPrivateKey(File.ReadAllBytes("private.key"), out _);

    var credentials = new SigningCredentials(
        new RsaSecurityKey(rsa), SecurityAlgorithms.RsaSha256);

    var token = new JwtSecurityToken(
        issuer: "https://auth.example.com",
        audience: "https://api.example.com",
        claims: GetClaims(user),
        expires: DateTime.UtcNow.AddHours(1),
        signingCredentials: credentials);

    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

### Task 4: JWKS endpoint — expose public key
```csharp
app.MapGet("/.well-known/jwks.json", () =>
{
    using var rsa = RSA.Create();
    rsa.ImportRSAPublicKey(File.ReadAllBytes("public.key"), out _);

    var parameters = rsa.ExportParameters(false);
    var jwk = new JsonWebKey
    {
        Kty = "RSA",
        Use = "sig",
        Alg = "RS256",
        Kid = "key-2024-01",  // Key ID — clients cache by kid
        N = Base64UrlEncoder.Encode(parameters.Modulus!),
        E = Base64UrlEncoder.Encode(parameters.Exponent!)
    };

    return Results.Ok(new { keys = new[] { jwk } });
});
```

Resource server (separate service) validate bằng cách fetch JWKS:
```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MetadataAddress = "https://auth.example.com/.well-known/openid-configuration";
        // Hoặc trực tiếp:
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = "https://auth.example.com",
            ValidAudience = "https://api.example.com",
            IssuerSigningKeyResolver = (token, secToken, kid, validationParams) =>
            {
                // Fetch public key từ JWKS endpoint
                var client = new HttpClient();
                var jwks = client.GetFromJsonAsync<JsonWebKeySet>(
                    "https://auth.example.com/.well-known/jwks.json").Result;
                return jwks!.Keys;
            }
        };
    });
```

### Task 5: Demo lỗ hổng JWT — alg:none attack
```csharp
// ATTACK: Thay đổi header alg="none", xóa signature
var maliciousToken = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxIiwicm9sZSI6ImFkbWluIn0.";

// FIX: Luôn validate algorithm
options.TokenValidationParameters = new TokenValidationParameters
{
    ValidAlgorithms = new[] { SecurityAlgorithms.RsaSha256 }, // Whitelist algorithms
    // ...
};
```

### Task 6: Key confusion attack (RS256 → HS256)
```
ATTACK: Nếu server verify HS256 với public key,
attacker có thể lấy public key (JWKS), sign với nó dùng HS256.
Server verify HS256 dùng public key → thành công (sai!)

FIX: Luôn hardcode ValidAlgorithms, không dùng alg từ header để chọn verifier.
```

### Task 7: JWT best practices
```csharp
options.TokenValidationParameters = new TokenValidationParameters
{
    ValidateIssuer = true,
    ValidateAudience = true,
    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    ClockSkew = TimeSpan.FromSeconds(30),  // Không để quá lớn
    ValidAlgorithms = new[] { "RS256" },   // Whitelist!
};
```

## Expected Output
- Decode JWT bằng tay, hiểu rõ từng phần
- Auth server: sign với RS256 private key
- Resource server: verify với public key qua JWKS endpoint
- `alg:none` token → 401 (rejected)
- JWKS endpoint: `GET /.well-known/jwks.json` → public key JSON

## Key Concepts
- **JWS (JSON Web Signature)**: JWT có signature (khác JWE — encrypted)
- **JWKS (JSON Web Key Set)**: JSON format cho public keys, clients fetch và cache
- **kid (Key ID)**: cho phép rotate keys mà không break existing tokens
- **alg:none**: attack dùng unsigned token — phải whitelist algorithms
- **Key rotation**: cập nhật kid trong JWKS → clients tự fetch key mới

## Resources
- [JWT.io](https://jwt.io/) — decode và inspect tokens online
- [RFC 7519 — JSON Web Token](https://www.rfc-editor.org/rfc/rfc7519)
- [RFC 7517 — JSON Web Key](https://www.rfc-editor.org/rfc/rfc7517)
- [JWT attacks - PortSwigger](https://portswigger.net/web-security/jwt)
