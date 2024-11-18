using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson;

namespace AuthService.Models
{
    public class Token
    {
        [BsonId]
        public ObjectId Id { get; set; } = ObjectId.GenerateNewId();

        public string User_id { get; set; }
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
    }
}