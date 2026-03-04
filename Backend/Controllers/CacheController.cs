using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CacheController : ControllerBase
    {
        private readonly ICacheService _cache;

        public CacheController(ICacheService cache)
        {
            _cache = cache;
        }

        [HttpPost("ping/{userId}")]
        public async Task<IActionResult> Ping(string userId)
        {
            await _cache.SetUserOnlineAsync(userId);
            return Ok();
        }

        [HttpGet("online-status/{userId}")]
        public async Task<IActionResult> CheckOnline(string userId)
        {
            var isOnline = await _cache.IsUserOnlineAsync(userId);
            return Ok(new { userId, isOnline });
        }

        [HttpPost("UpdateLocation")]
        public async Task<IActionResult> UpdateLocation(string userId, double lat, double lon)
        {
            await _cache.UpdateUserLocationAsync(userId, lat, lon);
            return Ok();
        }

        [HttpGet("NearbyUsers/{userId}")]
        public async Task<IActionResult> GetNearbyUsers(string userId, double radiusKm)
        {
            var nearbyUserIds = await _cache.GetNearbyUserIdsAsync(userId, radiusKm);
            return Ok(nearbyUserIds);
        }

        [HttpPost("MatchAlert")]
        public async Task<IActionResult> MatchAlert(string userId, string matchedWithId)
        {
            await _cache.MatchAlertAsync(userId, matchedWithId);
            return Ok();
        }
        [HttpGet("GetUserLocation/{userId}")]
        public async Task<IActionResult> GetUserLocation(string userId)
        {
            var position = await _cache.GetUserLocationAsync(userId);

            if (position == null)
                return NotFound(new { message = "User location not found" });
            double lat = position.Value.Latitude;
            double lon = position.Value.Longitude;

            return Ok(new { userId, Latitude = lat, Longitude = lon });
        }
    }
}