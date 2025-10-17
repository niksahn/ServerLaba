using AuthService.GraphQL.Inputs;
using AuthService.GraphQL.Types;
using AuthService.Models;
using HotChocolate;
using Microsoft.IdentityModel.Tokens;
using MongoDB.Driver;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace AuthService.GraphQL.Queries
{
    public class AuthQueries
    {
        private readonly IMongoCollection<Token> _tokens;
        private readonly string _secretKey = "your_very_secure_secret_key_here";

        public AuthQueries(IMongoClient client)
        {
            var database = client.GetDatabase("AuthDb");
            _tokens = database.GetCollection<Token>("Tokens");
        }

        [GraphQLDescription("Identify user from access token and verify required roles")]
        public async Task<UserInfoType> Identify(IdentifyInput input)
        {
            try
            {
                var principal = GetPrincipalFromExpiredToken(input.AccessToken);
                if (principal == null)
                {
                    return new UserInfoType
                    {
                        IsValid = false,
                        ErrorMessage = "Invalid access token"
                    };
                }

                var userId = principal.FindFirst("user_id")?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return new UserInfoType
                    {
                        IsValid = false,
                        ErrorMessage = "User ID not found in token"
                    };
                }

                var storedToken = await _tokens.Find(t => t.User_id == userId).FirstOrDefaultAsync();
                if (storedToken == null || storedToken.AccessToken != input.AccessToken)
                {
                    return new UserInfoType
                    {
                        IsValid = false,
                        ErrorMessage = "Access token invalid or expired"
                    };
                }

                var userRole = principal.FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;

                // Check if user has any of the required roles
                if (input.RequiredRoles.Any() && !input.RequiredRoles.Any(role => principal.IsInRole(role)))
                {
                    return new UserInfoType
                    {
                        IsValid = false,
                        ErrorMessage = "Insufficient permissions"
                    };
                }

                return new UserInfoType
                {
                    UserId = userId,
                    Role = userRole,
                    IsValid = true
                };
            }
            catch (Exception ex)
            {
                return new UserInfoType
                {
                    IsValid = false,
                    ErrorMessage = $"Token validation error: {ex.Message}"
                };
            }
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
    }
}
