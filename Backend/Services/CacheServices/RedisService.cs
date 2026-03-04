using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Backend.Services.Interfaces;
using StackExchange.Redis;

namespace Backend.Services.Redis
{
    public class RedisService : ICacheService
    {
        private readonly IDatabase _db;

        public RedisService(IConnectionMultiplexer redis)
        {
            _db = redis.GetDatabase();
        }
        public async Task MatchAlertAsync(string userId, string matchedWithId)
        {

            string key = $"match:alert:{userId}";

            // Podaci koje cuvamo
            var data = new { PartnerId = matchedWithId, Time = DateTime.UtcNow };
            string json = JsonSerializer.Serialize(data);

            //cuvamo 30 sekunde
            await _db.StringSetAsync(key, json, TimeSpan.FromSeconds(30));
        }

        public async Task SetUserOnlineAsync(string userId)
        {
            Console.WriteLine("Pocetak redis");

            string key = $"user:online:{userId}";
            await _db.StringSetAsync(key, "true", TimeSpan.FromMinutes(5));
            Console.WriteLine("Kraj redis");

        }
        public async Task<bool> IsUserOnlineAsync(string userId)
        {
            return await _db.KeyExistsAsync($"user:online:{userId}");
        }

        public async Task UpdateUserLocationAsync(string userId, double lat, double lon)
        {
            await _db.GeoAddAsync("user_locations", lon, lat, userId);
        }

        public async Task<List<string>> GetNearbyUserIdsAsync(string userId, double radiusKm)
        {
            var userLocation = await GetUserLocationAsync(userId);
            if (!userLocation.HasValue)
                return new List<string>();

            var results = await _db.GeoRadiusAsync(
                "user_locations",
                userLocation.Value.Longitude,
                userLocation.Value.Latitude,
                radiusKm,
                GeoUnit.Kilometers);

            return results
                .Select(x => x.Member.ToString())
                .Where(id => id != userId)
                .ToList();
        }
        public async Task<GeoPosition?> GetUserLocationAsync(string userId)
        {
            var results = await _db.GeoPositionAsync("user_locations", userId);

            return results;
        }
    }
}