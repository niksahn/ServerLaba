using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson;

namespace AuthService.Models
{
    public class Token
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        public string User_id { get; set; }
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public DateTime RefreshTokenExpiryTime { get; set; }
    }
}