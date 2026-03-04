using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs.User;
using Backend.Models;

namespace Backend.Services.Interfaces
{
    public interface IUserService
    {
        Task<User> GetUserByIdAsync(string id);
        Task<User> GetUserByEmailAsync(string email);
        Task CreateUserAsync(CreateUserDTO user);
        Task UpdateUserAsync(UpdateUserDTO user, string id);
        Task DeleteUserAsync(string id);
        Task<List<User>> GetAllUsersAsync();
        Task<List<User>> GetUsersByIdsAsync(List<string> ids);
        Task<List<User>> GetUsersByPreferencesAsync(User user);
        Task UpdateLocationAsync(string userId, double lat, double lon);

    }
}