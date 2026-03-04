using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Models;

namespace Backend.Services.Interfaces
{
    public interface IDiscoveryService
    {
        Task<List<(string UserId, int LikeCount)>> GetTopPicksAsync();
        Task<List<string>> GetRecommendations(string userId, List<string> nearbyIds);
        Task<List<string>> GetUsersByInterest(string userId);
        Task<List<User>> GetDiscoveryFeed(string userId);
    }
}