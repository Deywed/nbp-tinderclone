using Backend.DTOs;

namespace Backend.Services.Interfaces
{
    public interface IStatsService
    {
        Task<AppStatsDTO> GetAppStatsAsync();
    }
}
