using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Enum;
using Backend.Models;
using Backend.Repositories.Interfaces;
using Backend.Services.Interfaces;
using Neo4j.Driver;

namespace Backend.Services.GraphServices
{
    public class DiscoveryService : IDiscoveryService
    {
        private readonly INeo4JRepository _neo4JRepository;
        private readonly IDriver _driver;
        private readonly IUserService _userService;
        private readonly ICacheService _cacheService;
        public DiscoveryService(IDriver driver, IUserService userService, INeo4JRepository neo4JRepository, ICacheService cacheService)
        {
            _driver = driver;
            _userService = userService;
            _neo4JRepository = neo4JRepository;
            _cacheService = cacheService;
        }

        public async Task<List<User>> GetDiscoveryFeed(string userId)
        {
            // 1. Uzmi lokaciju iz redis
            var redisPosition = await _cacheService.GetUserLocationAsync(userId);
            double lat, lon;

            if (redisPosition.HasValue)
            {
                lat = redisPosition.Value.Latitude;
                lon = redisPosition.Value.Longitude;
            }
            else
            {
                // Fallback: Lokacije se ne nalazi u redis, uzmi iz mongo
                var currentUserForLocation = await _userService.GetUserByIdAsync(userId);
                var coords = currentUserForLocation.LastLocation?.Coordinates;
                if (coords == null || coords.Count < 2)
                    return new List<User>(); // lokacija nije poznata
                lon = coords[0];
                lat = coords[1];
                await _cacheService.UpdateUserLocationAsync(userId, lat, lon);
            }

            // 2. Ucitaj profil logovanog korisnika da bi izvukao njegove preference
            var currentUser = await _userService.GetUserByIdAsync(userId);
            var pref = currentUser.UserPreferences;

            // 3. Redis: Nađi ljude u krugu od 50km
            var nearbyIds = await _cacheService.GetNearbyUserIdsAsync(userId, 50);
            foreach (var id in nearbyIds)
            {
                Console.WriteLine($" Redis id u okolini: {id}");
            }

            List<User> nearbyUsers;
            if (nearbyIds.Count > 0)
            {
                // 4a. mongo: ucitaj profile korisnika u blizini
                nearbyUsers = await _userService.GetUsersByIdsAsync(nearbyIds);
            }
            else
            {
                // 4b. fallback: ako nema usera u redis-u, ucitaj korisnike po preferencama iz mongo bez geolokacije
                nearbyUsers = await _userService.GetUsersByPreferencesAsync(currentUser);
            }

            // 5. Filtriraj po polu i godinama
            var filtered = nearbyUsers
                .Where(u =>
                    (pref.InterestedIn == GenderEnum.Other || u.Gender == pref.InterestedIn)
                    && u.Age >= pref.MinAgePref
                    && u.Age <= pref.MaxAgePref
                )
                .Select(u => u.Id)
                .ToList();

            Console.WriteLine($"brok korisnika koji su prosli kroz filter pol/godine: {filtered.Count}");

            // 6. Neo4j: filtriraj one koje je korisnik već svajpovao ili blokirao, i sortiraj po zajedničkim interesovanjima
            var recommendedIds = await GetRecommendations(userId, filtered);

            Console.WriteLine($"Neo4j filter: {recommendedIds.Count} korisnika");

            // 7. Mongo: učitaj profile preporučenih korisnika
            var profiles = await _userService.GetUsersByIdsAsync(recommendedIds);

            // Očuvaj redosled sortiranja iz Neo4j-a
            return recommendedIds
                .Select(id => profiles.FirstOrDefault(u => u.Id == id))
                .Where(u => u != null)
                .ToList()!;
        }

        public async Task<List<string>> GetRecommendations(string userId, List<string> nearbyIds)
        {
            if (nearbyIds == null || nearbyIds.Count == 0)
                return new List<string>();

            await using var session = _driver.AsyncSession();
            return await session.ExecuteWriteAsync(async tx =>
            {
                const string query = @"
                    //prvi korisnik
                    MERGE (u:User {id: $userId})

                    WITH u
                    UNWIND $nearbyIds AS potentialId

                    //drugi korisnik                    
                    MERGE (other:User {id: potentialId})
                    
                    // filtriranje, izbacujemo one koje je korisnik već lajkovao, dislajkovao ili blokirao
                    WITH u, other
                    WHERE u.id <> other.id 
                    AND NOT (u)-[:LIKES|DISLIKES|BLOCKS]->(other)

                    // računanje zajedničkih interesovanja
                    OPTIONAL MATCH (u)-[:INTERESTED_IN]->(i:Interest)<-[:INTERESTED_IN]-(other)
                    
                    // vraćamo preporučene korisnike sortirane po broju zajedničkih interesovanja
                    WITH other, count(i) AS commonInterests
                    RETURN other.id AS Id
                    ORDER BY commonInterests DESC
                    LIMIT 20";

                var result = await tx.RunAsync(query, new { userId, nearbyIds });
                var list = new List<string>();
                while (await result.FetchAsync())
                {
                    list.Add(result.Current["Id"].As<string>());
                }
                return list;
            });
        }

        public async Task<List<(string UserId, int LikeCount)>> GetTopPicksAsync()
        {
            await using var session = _driver.AsyncSession();

            return await session.ExecuteReadAsync(async tx =>
            {
                var query = @"
                        MATCH (:User)-[r:LIKES]->(popular:User)
                        RETURN popular.id AS userId, count(r) AS likeCount
                        ORDER BY likeCount DESC
                        LIMIT 10";

                var result = await tx.RunAsync(query);
                var topPicks = new List<(string, int)>();

                while (await result.FetchAsync())
                {
                    var userId = result.Current["userId"].As<string>();
                    var likeCount = result.Current["likeCount"].As<int>();
                    topPicks.Add((userId, likeCount));
                }

                return topPicks;
            });
        }

        public async Task<List<string>> GetUsersByInterest(string interest)
        {
            return await _neo4JRepository.GetUsersByInterest(interest);
        }
    }
}