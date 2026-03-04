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
    public class SwipeController : ControllerBase
    {
        private readonly IMatchService _matchService;
        private readonly ISwipeService _swipeService;
        private readonly IUserService _userService;

        public SwipeController(IMatchService matchService, ISwipeService swipeService, IUserGraphService userGraphService, IUserService userService)
        {
            _matchService = matchService;
            _swipeService = swipeService;
            _userService = userService;
        }

        [HttpPost("Like")]
        public async Task<IActionResult> LikeUser(string userId, string likedUserId)
        {
            var result = await _swipeService.LikeUserAsync(userId, likedUserId);
            if (result)
            {
                return Ok("It's a match!");
            }
            return Ok("User liked successfully");
        }
        [HttpPost("Dislike")]
        public async Task<IActionResult> DislikeUser(string userId, string dislikedUserId)
        {
            await _swipeService.DislikeUserAsync(userId, dislikedUserId);
            return Ok("User disliked successfully");
        }

        [HttpGet("Matches/{userId}")]
        public async Task<IActionResult> GetMatches(string userId)
        {
            var matchedIds = await _matchService.GetMatchesForUserAsync(userId);

            Console.WriteLine($"[GetMatches] userId={userId} → Neo4j returned {matchedIds.Count} IDs: [{string.Join(", ", matchedIds)}]");

            if (matchedIds.Count == 0)
                return Ok(new List<object>());

            var profiles = await _userService.GetUsersByIdsAsync(matchedIds);

            Console.WriteLine($"[GetMatches] MongoDB returned {profiles.Count} profiles");

            return Ok(profiles);
        }
        [HttpDelete("RemoveMatch")]
        public async Task<IActionResult> RemoveMatch(string userId, string matchedUserId)
        {
            await _matchService.RemoveMatchAsync(userId, matchedUserId);
            return Ok("Match removed successfully");
        }
        [HttpPut("Block")]
        public async Task<IActionResult> BlockUser(string userId, string blockedUserId)
        {
            await _swipeService.BlockUserAsync(userId, blockedUserId);
            return Ok("User blocked successfully");
        }

    }
}