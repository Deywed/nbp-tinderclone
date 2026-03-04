using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Models;

namespace Backend.Services.Interfaces
{
    public interface INeo4JService
    {
        Task<bool> LikeUserAsync(string userId, string likedUserId);
        Task DislikeUserAsync(string userId, string dislikedUserId);
        Task<List<string>> GetMatchesByUserIdAsync(string userId);
        Task RemoveMatchAsync(string userId, string matchedUserId);
        Task BlockUserAsync(string userId, string blockedUserId);
        Task SetUserInterests(string userId, List<string> interests);
        Task<List<User>> GetUsersByInterest(string interest);
        Task<List<User>> GetTopPicks();
        Task<List<User>> GetRecommendations(string userId, List<string> nearbyIds);
        Task RegisterUser(string userId);

    }
}