using HotChocolate;

namespace AuthService.GraphQL.Inputs
{
    [GraphQLName("LoginInput")]
    public class LoginInput
    {
        [GraphQLDescription("Username for authentication")]
        public string UserName { get; set; } = string.Empty;

        [GraphQLDescription("Password for authentication")]
        public string Password { get; set; } = string.Empty;
    }
}
