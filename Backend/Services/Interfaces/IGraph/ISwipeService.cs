using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services.Interfaces
{
    public interface ISwipeService
    {
        Task<bool> LikeUserAsync(string userId, string likedUserId);
        Task DislikeUserAsync(string userId, string dislikedUserId);
        Task BlockUserAsync(string userId, string blockedUserId);

    }
}