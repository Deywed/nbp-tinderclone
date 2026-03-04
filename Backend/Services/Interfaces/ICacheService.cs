using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace Backend.Services.Interfaces
{
    public interface ICacheService
    {
        Task SetUserOnlineAsync(string userId);
        Task MatchAlertAsync(string userId, string matchedWithId);
        Task<bool> IsUserOnlineAsync(string userId);
        Task UpdateUserLocationAsync(string userId, double lat, double lon);
        Task<List<string>> GetNearbyUserIdsAsync(string userId, double radiusKm);
        Task<GeoPosition?> GetUserLocationAsync(string userId);
    }
}