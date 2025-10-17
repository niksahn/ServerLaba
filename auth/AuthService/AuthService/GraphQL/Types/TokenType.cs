using AuthService.Models;
using HotChocolate;

namespace AuthService.GraphQL.Types
{
    [GraphQLName("TokenType")]
    public class TokenType
    {
        public string Id { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;

        public static TokenType FromModel(Token token)
        {
            return new TokenType
            {
                Id = token.Id.ToString(),
                UserId = token.User_id,
                AccessToken = token.AccessToken,
                RefreshToken = token.RefreshToken
            };
        }
    }
}
