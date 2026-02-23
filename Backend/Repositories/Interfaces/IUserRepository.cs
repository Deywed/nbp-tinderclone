using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Models;
using Backend.DTOs.User;
using MongoDB.Driver;

namespace Backend.Repositories.Interfaces
{
    public interface IUserRepository
    {
        Task CreateUserAsync(User user);
        Task<User> GetUserByIdAsync(Guid id);
        Task<User> GetUserByEmailAsync(string email);
        Task<List<User>> GetAllUsersAsync();
        Task<List<User>> GetUsersByGender(User user);
        Task UpdateUserAsync(User user);
        Task DeleteUserAsync(Guid id);
        Task<List<User>> GetUsersByPreferencesAsync(User user);
    }
}