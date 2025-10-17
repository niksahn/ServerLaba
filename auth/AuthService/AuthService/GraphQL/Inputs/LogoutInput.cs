using HotChocolate;

namespace AuthService.GraphQL.Inputs
{
    [GraphQLName("LogoutInput")]
    public class LogoutInput
    {
        [GraphQLDescription("Access token to logout")]
        public string AccessToken { get; set; } = string.Empty;
    }
}
