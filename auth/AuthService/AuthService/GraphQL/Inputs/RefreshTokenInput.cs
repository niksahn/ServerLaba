using HotChocolate;

namespace AuthService.GraphQL.Inputs
{
    [GraphQLName("RefreshTokenInput")]
    public class RefreshTokenInput
    {
        [GraphQLDescription("Refresh token to generate new access token")]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
