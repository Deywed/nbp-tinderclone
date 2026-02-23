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
            // GetDatabase() dobavlja referencu na Redis bazu podataka.
            // Redis je single-threaded i veoma brz, pa je ovo lagana operacija.
            _db = redis.GetDatabase();
        }
        public async Task MatchAlertAsync(string userId, string matchedWithId)
        {

            // Ključ koji označava da se desio novi match za određenog korisnika.
            string key = $"match:alert:{userId}";

            // Podaci koje čuvamo (npr. ID osobe sa kojom je match).
            var data = new { PartnerId = matchedWithId, Time = DateTime.UtcNow };
            string json = JsonSerializer.Serialize(data);

            // Čuvamo u Redisu na npr. 30 sekundi. 
            // Dovoljno dugo da front-end "pokupi" informaciju i prikaže vatromet.
            await _db.StringSetAsync(key, json, TimeSpan.FromSeconds(30));
        }

        public async Task SetUserOnlineAsync(string userId)
        {
            // Formiramo ključ koristeći konvenciju sa dvotačkom.
            string key = $"user:online:{userId}";

            // StringSetAsync upisuje podatak u Redis.
            // Treći parametar (TimeSpan) je TTL (Time To Live). 
            // Postavljamo na 5 minuta. Ako se korisnik ne javi ponovo, Redis sam briše ključ.
            await _db.StringSetAsync(key, "true", TimeSpan.FromMinutes(5));
        }
        public async Task<bool> IsUserOnlineAsync(string userId)
        {
            return await _db.KeyExistsAsync($"user:online:{userId}");
        }
    }
}