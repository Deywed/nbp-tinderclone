using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Models;

namespace Backend.Repositories.Interfaces
{
    public interface INeo4JRepository
    {
        Task CreateLikeAsync(string userId, string likedUserId);
        Task CreateDislikeAsync(string userId, string dislikedUserId);
        Task<List<string>> GetExcludedUsersAsync(string userId);
        Task<List<string>> GetMatchesByUserIdAsync(string userId);
        Task BlockUserAsync(string userId, string blockedUserId);
        Task SetUserInterests(string userid, List<string> interests);
        Task<List<string>> GetUsersByInterest(string interest);
        Task<List<string>> GetTopPicks();

    }
}