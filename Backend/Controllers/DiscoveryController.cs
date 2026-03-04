using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DiscoveryController : ControllerBase
    {
        private readonly IDiscoveryService _discoveryService;
        private readonly IUserService _userService;
        public DiscoveryController(IDiscoveryService discoveryService, IUserService userService)
        {
            _discoveryService = discoveryService;
            _userService = userService;
        }

        [HttpGet("GetUsersByInterest/{interest}")]
        public async Task<IActionResult> GetUsersByInterest(string interest)
        {
            var users = await _discoveryService.GetUsersByInterest(interest);
            return Ok(users);
        }

        [HttpGet("GetTopPicks")]
        public async Task<IActionResult> GetTopPicks()
        {
            var topPickItems = await _discoveryService.GetTopPicksAsync();
            var ids = topPickItems.Select(t => t.UserId).ToList();
            var profiles = await _userService.GetUsersByIdsAsync(ids);

            var likeCountMap = topPickItems.ToDictionary(t => t.UserId, t => t.LikeCount);
            var response = profiles
                .Where(u => u.Id != null && likeCountMap.ContainsKey(u.Id))
                .OrderBy(u => ids.IndexOf(u.Id!))
                .Select(u => new TopPickResponseDTO
                {
                    User = u,
                    LikeCount = likeCountMap[u.Id!]
                })
                .ToList();

            return Ok(response);
        }

        [HttpGet("GetRecommendations/{userId}")]
        public async Task<IActionResult> GetRecommendations(string userId, [FromQuery] List<string> nearbyIds)
        {
            var recommendations = await _discoveryService.GetRecommendations(userId, nearbyIds);
            return Ok(recommendations);
        }
        [HttpGet("GetDiscoveryFeed/{userId}")]
        public async Task<IActionResult> GetDiscoveryFeed(string userId)
        {
            var feed = await _discoveryService.GetDiscoveryFeed(userId);
            return Ok(feed);
        }
        [HttpPut("update-location/{userId}")]
        public async Task<IActionResult> UpdateLocation(string userId, [FromBody] LocationUpdateDTO locationDto)
        {
            await _userService.UpdateLocationAsync(userId, locationDto.Latitude, locationDto.Longitude);
            return Ok(new { message = "Location updated successfully" });
        }
    }
}