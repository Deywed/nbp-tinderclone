using Backend.DTOs;
using Backend.Enum;
using Backend.Models;
using Backend.Services.Interfaces;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Backend.Services.CollectionServices
{
    public class StatsService : IStatsService
    {
        private readonly IMongoCollection<User> _users;

        private static readonly Dictionary<int, string> AgeBucketLabels = new()
        {
            { 18, "18–24" },
            { 25, "25–29" },
            { 30, "30–34" },
            { 35, "35–39" },
            { 40, "40–49" },
            { 50, "50+" }
        };

        public StatsService(IMongoDatabase database)
        {
            _users = database.GetCollection<User>("Users");
        }

        public async Task<AppStatsDTO> GetAppStatsAsync()
        {
            var totalUsers = (int)await _users.CountDocumentsAsync(FilterDefinition<User>.Empty);

            var topInterests = await GetTopInterestsAsync();
            var genderDistribution = await GetGenderDistributionAsync();
            var ageDistribution = await GetAgeDistributionAsync();
            var averageAgeByGender = await GetAverageAgeByGenderAsync();

            return new AppStatsDTO
            {
                TotalUsers = totalUsers,
                TopInterests = topInterests,
                GenderDistribution = genderDistribution,
                AgeDistribution = ageDistribution,
                AverageAgeByGender = averageAgeByGender
            };
        }

        // Pipeline 1: Top interesi
        // $unwind rastavlja niz Interests u zasebne dokumente,
        // $group broji pojavljivanja svake vrednosti, 
        // $sort i $limit vraćaju top 8
        // $project formatira izlaz
        private async Task<List<InterestStatDTO>> GetTopInterestsAsync()
        {
            var pipeline = new BsonDocument[]
            {
                new("$unwind", "$Interests"),
                new("$group", new BsonDocument
                {
                    { "_id", "$Interests" },
                    { "count", new BsonDocument("$sum", 1) }
                }),
                new("$sort", new BsonDocument("count", -1)),
                new("$limit", 8),
                new("$project", new BsonDocument
                {
                    { "Interest", "$_id" },
                    { "Count", "$count" },
                    { "_id", 0 }
                })
            };

            var cursor = await _users.AggregateAsync<BsonDocument>(pipeline);
            var docs = await cursor.ToListAsync();

            return docs.Select(d => new InterestStatDTO
            {
                Interest = d["Interest"].AsString,
                Count = d["Count"].AsInt32
            }).ToList();
        }

        // Pipeline 2: Raspodela polova
        // $group po polju Gender
        // $project mapira int u string
        private async Task<List<GenderStatDTO>> GetGenderDistributionAsync()
        {
            var pipeline = new BsonDocument[]
            {
                new("$group", new BsonDocument
                {
                    { "_id", "$Gender" },
                    { "count", new BsonDocument("$sum", 1) }
                }),
                new("$sort", new BsonDocument("_id", 1))
            };

            var cursor = await _users.AggregateAsync<BsonDocument>(pipeline);
            var docs = await cursor.ToListAsync();

            return docs.Select(d => new GenderStatDTO
            {
                Gender = ((GenderEnum)d["_id"].AsInt32).ToString(),
                Count = d["count"].AsInt32
            }).ToList();
        }

        //Pipeline 3: Distribucija po godinama ($bucket)
        // $bucket grupiše korisnike u starosne grupe na osnovu polja Age
        // boundaries definišu granice grupa, default hvata sve van tih granica
        // $sort sortira rezultate po starosnim grupama

        private async Task<List<AgeDistributionDTO>> GetAgeDistributionAsync()
        {
            var pipeline = new BsonDocument[]
            {
                new("$bucket", new BsonDocument
                {
                    { "groupBy", "$Age" },
                    { "boundaries", new BsonArray { 18, 25, 30, 35, 40, 50, 100 } },
                    { "default", "other" },
                    { "output", new BsonDocument
                        {
                            { "count", new BsonDocument("$sum", 1) }
                        }
                    }
                }),
                new("$sort", new BsonDocument("_id", 1))
            };

            var cursor = await _users.AggregateAsync<BsonDocument>(pipeline);
            var docs = await cursor.ToListAsync();

            return docs
                .Where(d => d["_id"].BsonType == BsonType.Int32)
                .Select(d =>
                {
                    var lowerBound = d["_id"].AsInt32;
                    var label = AgeBucketLabels.TryGetValue(lowerBound, out var l) ? l : $"{lowerBound}+";
                    return new AgeDistributionDTO
                    {
                        Range = label,
                        Count = d["count"].AsInt32
                    };
                })
                .ToList();
        }

        // Pipeline 4: Prosecne godine po polu ($group + $avg)
        // $group po pol i računa prosečnu vrednost polja Age za svaki pol
        // $sort sortira rezultate po polu
        // $project mapira int u string
        private async Task<List<AverageAgeByGenderDTO>> GetAverageAgeByGenderAsync()
        {
            var pipeline = new BsonDocument[]
            {
                new("$group", new BsonDocument
                {
                    { "_id", "$Gender" },
                    { "avgAge", new BsonDocument("$avg", "$Age") }
                }),
                new("$sort", new BsonDocument("_id", 1))
            };

            var cursor = await _users.AggregateAsync<BsonDocument>(pipeline);
            var docs = await cursor.ToListAsync();

            return docs.Select(d => new AverageAgeByGenderDTO
            {
                Gender = ((GenderEnum)d["_id"].AsInt32).ToString(),
                AverageAge = Math.Round(d["avgAge"].ToDouble(), 1)
            }).ToList();
        }
    }
}
