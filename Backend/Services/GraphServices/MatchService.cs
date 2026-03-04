using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Services.Interfaces;
using Neo4j.Driver;

namespace Backend.Services.GraphServices
{
    public class MatchService : IMatchService
    {
        private readonly IDriver _driver;
        private readonly ICacheService _cacheService;

        public MatchService(IDriver driver, ICacheService cacheService)
        {
            _driver = driver;
            _cacheService = cacheService;
        }

        public async Task<List<string>> GetMatchesForUserAsync(string userId)
        {
            await _cacheService.SetUserOnlineAsync(userId);

            await using var session = _driver.AsyncSession();
            return await session.ExecuteReadAsync(async tx =>
            {
                var query = @"
                MATCH (u: User {id: $userId})-[:LIKES]->(liked: User)
                MATCH (liked)-[:LIKES]->(u) 
                RETURN liked.id AS likedUserId";
                var result = await tx.RunAsync(query, new { userId });

                var matchedUserIds = new List<string>();
                while (await result.FetchAsync())
                {
                    matchedUserIds.Add(result.Current["likedUserId"].As<string>());
                }
                return matchedUserIds;
            });
        }

        public async Task RemoveMatchAsync(string userId, string matchedUserId)
        {
            await _cacheService.SetUserOnlineAsync(userId);

            await using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                MATCH (u1: User {id: $userId})-[r1:LIKES]->(u2: User {id: $matchedUserId})
                MATCH (u2)-[r2:LIKES]->(u1)
                DELETE r1, r2";
                await tx.RunAsync(query, new { userId, matchedUserId });
            }
            );
        }
    }
}