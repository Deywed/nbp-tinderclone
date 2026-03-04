using Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StatsController : ControllerBase
    {
        private readonly IStatsService _statsService;

        public StatsController(IStatsService statsService)
        {
            _statsService = statsService;
        }
        [HttpGet]
        public async Task<IActionResult> GetStats()
        {
            var stats = await _statsService.GetAppStatsAsync();
            return Ok(stats);
        }
    }
}
