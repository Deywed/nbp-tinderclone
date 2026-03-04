using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services.Interfaces
{
    public interface IMatchService
    {
        Task<List<string>> GetMatchesForUserAsync(string userId);
        Task RemoveMatchAsync(string userId, string matchedUserId);
    }
}