using HotChocolate;

namespace AuthService.GraphQL.Types
{
    [GraphQLName("AuthPayloadType")]
    public class AuthPayloadType
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }
    }
}
