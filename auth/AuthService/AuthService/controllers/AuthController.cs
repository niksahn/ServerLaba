﻿using AuthService.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using MongoDB.Driver;
using MongoDB.Driver.Linq;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace AuthService.Controllers
{
    [ApiController]
    [Route("auth")]
    public class AuthController : ControllerBase
    {
        private readonly ApiService api;
        private readonly IConfiguration configuration;
        private readonly IMongoCollection<Token> _tokens;
        private readonly string _secretKey = "your_very_secure_secret_key_here";
        private readonly int AccessTokenDurationMinutes = 15;
        private readonly int RefreshTokenDurationMinutes = 1440; // 24 hours

        public AuthController(IMongoClient client, ApiService _api, IConfiguration _configuration)
        {
            var database = client.GetDatabase("AuthDb");
            api = _api;
            _tokens = database.GetCollection<Token>("Tokens");
            configuration = _configuration;
        }

        [HttpPost("")]
        public async Task<IActionResult> Authenticate([FromBody] LoginRequest request)
        {
            var user_id = await ValidateUser(request.UserName, request.Password);
            if (user_id == null) return BadRequest("Invalid credentials");

            var tokenPair = GenerateTokens(user_id.Id, user_id.Role);
            var filter = Builders<Token>.Filter.Eq(t => t.User_id, user_id.Id);

            // Проверка, существует ли уже такой документ
            var existingToken = _tokens.Find(filter).FirstOrDefault();

            if (existingToken != null)
            {
                // Сохраняем существующий _id
                tokenPair.Id = existingToken.Id;
            }

            // Выполняем операцию замены с сохранением _id
            _tokens.ReplaceOne(filter, tokenPair, new ReplaceOptions { IsUpsert = true });
            return Ok(new { tokenPair.AccessToken, tokenPair.RefreshToken });
        }

        [HttpPost("logout")]
        public IActionResult Logout([FromBody] LogoutRequest request)
        {
            if (_tokens.DeleteOne(t => t.AccessToken == request.token).IsAcknowledged) return Ok();
            else return BadRequest();
        }

        [HttpPost("refresh")]
        public IActionResult Refresh([FromBody] RefreshRequest request)
        {
            var token = _tokens.Find(t => t.RefreshToken == request.RefreshToken).FirstOrDefault();

            var principal = GetPrincipalFromExpiredToken(request.RefreshToken);

            if (token == null)
            {
                return BadRequest("Invalid or expired refresh token");
            }
             var newTokens = GenerateTokens(token.User_id, principal.FindFirstValue(ClaimTypes.Role));
            _tokens.ReplaceOne(t => t.User_id == token.User_id, newTokens);

            return Ok(new { newTokens.AccessToken, newTokens.RefreshToken });
        }

        [HttpPost("identify")]
        public IActionResult Identify([FromBody] IdentifyRequest request)
        {
            ClaimsPrincipal? principal;
            try {
                principal = GetPrincipalFromExpiredToken(request.AccessToken);
            }
            catch {
                principal = null;
            }

            if (principal == null) return Unauthorized("Invalid access token");

            var userName = principal.FindFirst("user_id").Value;
            var storedToken = _tokens.Find(t => t.User_id.ToString() == userName).FirstOrDefault();

            if (storedToken == null || storedToken.AccessToken != request.AccessToken )
            {
                return Unauthorized("Access token invalid or expired");
            }

            if(!request.Role.Any(x=>principal.IsInRole(x)))
            {
               return Forbid("Wrong role");
            }
            return Ok(new { userName });
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

        private string GenerateAccessToken(string userName, string role, int lifeTime )
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

        private string GenerateRefreshToken()
        {
            return Guid.NewGuid().ToString("N");
        }

        private ClaimsPrincipal GetPrincipalFromExpiredToken(string token)
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
                throw new SecurityTokenException("Invalid token");

            return principal;
        }

        private async Task<IdentifyResponse?> ValidateUser(string userName, string _password)
        {
            return await api.PostResourceAsync<IdentifyResponse, IdentifyExternalRequest>(configuration.GetConnectionString("UserService") + "users/identify",
                new IdentifyExternalRequest
                {                Name = userName,
                Password=_password       } 
                ); 
        }
    }

    public class LoginRequest
    {
        public string UserName { get; set; }
        public string Password { get; set; }
    }

    public class LogoutRequest
    {
        public string token { get; set; }
    }

    public class RefreshRequest
    {
        public string RefreshToken { get; set; }
    }

    public class IdentifyRequest
    {
        public string AccessToken { get; set; }
        public List<string> Role { get; set; }
    }

    public class IdentifyResponse
    {
        public string Id { get; set; }
        public string Role { get; set; }

    }

    public class IdentifyExternalRequest
    {
        public string Name { get; set; }
        public string Password { get; set; }
    }
}