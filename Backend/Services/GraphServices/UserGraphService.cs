using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Services.Interfaces;
using Neo4j.Driver;

namespace Backend.Services.GraphServices
{
    public class UserGraphService : IUserGraphService
    {
        private readonly IDriver _driver;
        public UserGraphService(IDriver driver)
        {
            _driver = driver;
        }

        public async Task RegisterUserAsync(string userId)
        {
            using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                MERGE (u: User {id: $userId})";
                await tx.RunAsync(query, new { userId });
            });
        }

        public async Task SetUserInterestsAsync(string userId, List<string> interests)
        {
            using var session = _driver.AsyncSession();
            await session.ExecuteWriteAsync(async tx =>
            {
                var query = @"
                MATCH (u: User {id: $userId})
                OPTIONAL MATCH (u)-[r:INTERESTED_IN]->()
                DELETE r
                WITH u
                UNWIND $interests AS interest
                MERGE (i: Interest {name: interest})
                MERGE (u)-[:INTERESTED_IN]->(i)";
                await tx.RunAsync(query, new { userId, interests });
            });
        }
    }
}