using HotChocolate;

namespace AuthService.GraphQL.Inputs
{
    [GraphQLName("IdentifyInput")]
    public class IdentifyInput
    {
        [GraphQLDescription("Access token to identify user")]
        public string AccessToken { get; set; } = string.Empty;

        [GraphQLDescription("Required roles for authorization")]
        public List<string> RequiredRoles { get; set; } = new List<string>();
    }
}
