using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Hubs;
using Backend.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;
using Neo4j.Driver;

namespace Backend.Services.GraphServices
{
    public class SwipeService : ISwipeService
    {
        private readonly IDriver _driver;
        private readonly ICacheService _cacheService;
        private readonly IHubContext<MatchHub> _hubContext;

        public SwipeService(IDriver driver, ICacheService cacheService, IHubContext<MatchHub> hubContext)
        {
            _driver = driver;
            _cacheService = cacheService;
            _hubContext = hubContext;
        }

        public async Task BlockUserAsync(string userId, string blockedUserId)
        {

            await using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
           {
               var query = @"
                MATCH (u1:User {id: $userId})
                MATCH (u2:User {id: $blockedUserId})
                MATCH (u1)-[r1:LIKES]-(u2)
                DELETE r1
                MERGE (u1)-[b:BLOCKED]->(u2)
                ON CREATE SET b.createdAt = datetime()";
               await tx.RunAsync(query, new { userId, blockedUserId });
           });

        }

        public async Task DislikeUserAsync(string userId, string dislikedUserId)
        {

            await using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                MERGE (u1: User {id: $userId})
                MERGE (u2: User {id: $dislikedUserId})
                MERGE (u1)-[:DISLIKES]->(u2)";
                await tx.RunAsync(query, new { userId, dislikedUserId });
            }
            );
        }

        public async Task<bool> LikeUserAsync(string userId, string likedUserId)
        {

            await using var session = _driver.AsyncSession();

            var isMatch = await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                    MERGE (u1:User {id: $userId})
                    MERGE (u2:User {id: $likedUserId})
                    MERGE (u1)-[r:LIKES]->(u2)
                    ON CREATE SET r.createdAt = datetime()
                    WITH u1, u2
                    OPTIONAL MATCH (u2)-[r2:LIKES]->(u1)
                    RETURN r2 IS NOT NULL AS isMatch";
                var result = await tx.RunAsync(query, new { userId, likedUserId });
                if (await result.FetchAsync())
                {
                    return result.Current["isMatch"].As<bool>();
                }
                return false;
            }
            );
            if (isMatch)
            {
                await _cacheService.MatchAlertAsync(userId, likedUserId);
                await _cacheService.MatchAlertAsync(likedUserId, userId);

                await _hubContext.Clients.Group(userId)
                    .SendAsync("ReceiveMatchNotification", likedUserId);
                await _hubContext.Clients.Group(likedUserId)
                    .SendAsync("ReceiveMatchNotification", userId);
            }

            return isMatch;
        }
    }
}