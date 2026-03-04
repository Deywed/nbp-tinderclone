using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Models;
using Backend.Repositories.Interfaces;
using Neo4j.Driver;

namespace Backend.Repositories
{
    public class Neo4Repository : INeo4JRepository
    {
        private readonly IDriver _driver;
        public Neo4Repository(IDriver driver)
        {
            _driver = driver;
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
            }
            );
        }

        public async Task CreateDislikeAsync(string userId, string dislikedUserId)
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

        public async Task CreateLikeAsync(string userId, string likedUserId)
        {
            await using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                MERGE (u1: User {id: $userId})
                MERGE (u2: User {id: $likedUserId})
                MERGE (u1)-[:LIKES]->(u2)";
                await tx.RunAsync(query, new { userId, likedUserId });
            }
            );
        }

        public async Task<List<string>> GetExcludedUsersAsync(string userId)
        {
            //TODO:
            throw new NotImplementedException();
        }

        public async Task<List<string>> GetMatchesByUserIdAsync(string userId)
        {
            await using var session = _driver.AsyncSession();

            return await session.ExecuteReadAsync(async tx =>
            {
                var query = @"
                    MATCH (u: User {id: $userId})-[:LIKES]->(liked: User)
                    MATCH (liked)-[:LIKES]->(u) 
                    RETURN liked.id AS marchedUserId";

                var result = await tx.RunAsync(query, new { userId });

                return await result.ToListAsync(record => record["marchedUserId"].As<string>());
            }
            );
        }

        public async Task<List<string>> GetTopPicks()
        {
            await using var session = _driver.AsyncSession();
            return await session.ExecuteReadAsync(async tx =>
            {
                const string query = @"
                    MATCH (u:User)-[:LIKES]->(liked:User)
                    RETURN liked.id AS userId, COUNT(*) AS likeCount
                    ORDER BY likeCount DESC
                    LIMIT 10";

                var result = await tx.RunAsync(query);

                return await result.ToListAsync(record => record["userId"].As<string>());
            });
        }

        public async Task<List<User>> GetUsersByInterest(string interest)
        {
            await using var session = _driver.AsyncSession();
            return await session.ExecuteReadAsync(async tx =>
            {
                const string query = @"
                    MATCH (u:User)-[:INTERESTED_IN]->(:Interest {name: $interest})
                    RETURN DISTINCT u.id AS userId";

                var result = await tx.RunAsync(query, new { interest });

                return await result.ToListAsync(record => new User
                {
                    Id = record["userId"].As<string>()
                });
            });
        }

        public async Task SetUserInterests(string userId, List<string> interests)
        {
            await using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                    MERGE (u:User {id: $userId})
                    WITH u
                    OPTIONAL MATCH (u)-[r:INTERESTED_IN]->(:Interest)
                    DELETE r
                    WITH u
                    UNWIND $interests AS interestName
                    MERGE (i:Interest {name: interestName})
                    MERGE (u)-[:INTERESTED_IN]->(i)";
                await tx.RunAsync(query, new { userId, interests });
            });
        }

        Task<List<string>> INeo4JRepository.GetUsersByInterest(string interest)
        {
            throw new NotImplementedException();
        }
    }
}