using HotChocolate;

namespace AuthService.GraphQL.Types
{
    [GraphQLName("UserInfoType")]
    public class UserInfoType
    {
        public string UserId { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public bool IsValid { get; set; }
        public string? ErrorMessage { get; set; }
    }
}
