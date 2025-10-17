using AuthService.GraphQL.Inputs;
using AuthService.GraphQL.Types;
using AuthService.Models;
using HotChocolate;
using Microsoft.IdentityModel.Tokens;
using MongoDB.Driver;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace AuthService.GraphQL.Mutations
{
    public class AuthMutations
    {
        private readonly IMongoCollection<Token> _tokens;
        private readonly ApiService _apiService;
        private readonly IConfiguration _configuration;
        private readonly string _secretKey = "your_very_secure_secret_key_here";
        private readonly int AccessTokenDurationMinutes = 15;
        private readonly int RefreshTokenDurationMinutes = 1440; // 24 hours

        public AuthMutations(IMongoClient client, ApiService apiService, IConfiguration configuration)
        {
            var database = client.GetDatabase("AuthDb");
            _tokens = database.GetCollection<Token>("Tokens");
            _apiService = apiService;
            _configuration = configuration;
        }

        [GraphQLDescription("Authenticate user with username and password")]
        public async Task<AuthPayloadType> Authenticate(LoginInput input)
        {
            try
            {
                var user = await ValidateUser(input.UserName, input.Password);
                if (user == null)
                {
                    return new AuthPayloadType
                    {
                        Success = false,
                        ErrorMessage = "Invalid credentials"
                    };
                }

                var tokenPair = GenerateTokens(user.Id, user.Role);
                var filter = Builders<Token>.Filter.Eq(t => t.User_id, user.Id);

                // Check if token already exists
                var existingToken = await _tokens.Find(filter).FirstOrDefaultAsync();
                if (existingToken != null)
                {
                    tokenPair.Id = existingToken.Id;
                }

                // Replace or insert token
                await _tokens.ReplaceOneAsync(filter, tokenPair, new ReplaceOptions { IsUpsert = true });

                return new AuthPayloadType
                {
                    AccessToken = tokenPair.AccessToken,
                    RefreshToken = tokenPair.RefreshToken,
                    UserId = user.Id,
                    Role = user.Role,
                    Success = true
                };
            }
            catch (Exception ex)
            {
                return new AuthPayloadType
                {
                    Success = false,
                    ErrorMessage = $"Authentication error: {ex.Message}"
                };
            }
        }

        [GraphQLDescription("Refresh access token using refresh token")]
        public async Task<AuthPayloadType> Refresh(RefreshTokenInput input)
        {
            try
            {
                var token = await _tokens.Find(t => t.RefreshToken == input.RefreshToken).FirstOrDefaultAsync();
                if (token == null)
                {
                    return new AuthPayloadType
                    {
                        Success = false,
                        ErrorMessage = "Invalid or expired refresh token"
                    };
                }

                var principal = GetPrincipalFromExpiredToken(input.RefreshToken);
                if (principal == null)
                {
                    return new AuthPayloadType
                    {
                        Success = false,
                        ErrorMessage = "Invalid refresh token"
                    };
                }

                var userRole = principal.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
                var newTokens = GenerateTokens(token.User_id, userRole);
                
                await _tokens.ReplaceOneAsync(t => t.User_id == token.User_id, newTokens);

                return new AuthPayloadType
                {
                    AccessToken = newTokens.AccessToken,
                    RefreshToken = newTokens.RefreshToken,
                    UserId = token.User_id,
                    Role = userRole,
                    Success = true
                };
            }
            catch (Exception ex)
            {
                return new AuthPayloadType
                {
                    Success = false,
                    ErrorMessage = $"Token refresh error: {ex.Message}"
                };
            }
        }

        [GraphQLDescription("Logout user by invalidating access token")]
        public async Task<AuthPayloadType> Logout(LogoutInput input)
        {
            try
            {
                var result = await _tokens.DeleteOneAsync(t => t.AccessToken == input.AccessToken);
                
                return new AuthPayloadType
                {
                    Success = result.IsAcknowledged && result.DeletedCount > 0,
                    ErrorMessage = result.IsAcknowledged && result.DeletedCount == 0 ? "Token not found" : null
                };
            }
            catch (Exception ex)
            {
                return new AuthPayloadType
                {
                    Success = false,
                    ErrorMessage = $"Logout error: {ex.Message}"
                };
            }
        }

        private Token GenerateTokens(string userName, string role)
        {
            var accessToken = GenerateAccessToken(userName, role, AccessTokenDurationMinutes);
            var refreshToken = GenerateAccessToken(userName, role, RefreshTokenDurationMinutes);

            return new Token
            {
                User_id = userName,
                AccessToken = accessToken,
                RefreshToken = refreshToken,
            };
        }

        private string GenerateAccessToken(string userName, string role, int lifeTime)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_secretKey);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[] { new Claim("user_id", userName), new Claim(ClaimTypes.Role, role) }),
                Expires = DateTime.UtcNow.AddMinutes(lifeTime),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        private ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
        {
            try
            {
                var tokenValidationParameters = new TokenValidationParameters
                {
                    ValidateAudience = false,
                    ValidateIssuer = false,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(_secretKey)),
                    ValidateLifetime = true
                };

                var tokenHandler = new JwtSecurityTokenHandler();
                SecurityToken securityToken;
                var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out securityToken);
                var jwtSecurityToken = securityToken as JwtSecurityToken;

                if (jwtSecurityToken == null || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
                    return null;

                return principal;
            }
            catch
            {
                return null;
            }
        }

        private async Task<IdentifyResponse?> ValidateUser(string userName, string password)
        {
            return await _apiService.PostResourceAsync<IdentifyResponse, IdentifyExternalRequest>(
                _configuration.GetConnectionString("UserService") + "users/identify",
                new IdentifyExternalRequest
                {
                    Name = userName,
                    Password = password
                });
        }
    }

    // Helper classes for user validation
    public class IdentifyResponse
    {
        public string Id { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
    }

    public class IdentifyExternalRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
