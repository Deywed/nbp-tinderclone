using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Services.Interfaces;
using Backend.Models;
using MongoDB.Driver;
using Backend.Repositories.Interfaces;
using Backend.DTOs.User;
using AutoMapper;

namespace Backend.Services
{
    public class UserService : IUserService
    {
        private readonly ICacheService _cacheService;
        private readonly IUserRepository _userRepository;
        private readonly IMapper _mapper;
        private readonly IUserGraphService _userGraphService;

        public UserService(ICacheService cacheService, IUserRepository userRepository, IMapper mapper, IUserGraphService userGraphService)
        {
            _cacheService = cacheService;
            _userRepository = userRepository;
            _userGraphService = userGraphService;
            _mapper = mapper;
        }
        public async Task CreateUserAsync(CreateUserDTO userDto)
        {
            var existingUser = await _userRepository.GetUserByEmailAsync(userDto.Email);
            if (existingUser != null) throw new ArgumentException("Email already in use");

            if (string.IsNullOrWhiteSpace(userDto.Password))
                throw new ArgumentException("Password is required");

            var user = _mapper.Map<User>(userDto);
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(userDto.Password);

            await _userRepository.CreateUserAsync(user);
            await _cacheService.SetUserOnlineAsync(user.Id);
            await _userGraphService.RegisterUserAsync(user.Id);
            await _userGraphService.SetUserInterestsAsync(user.Id, userDto.Interests);
        }

        public async Task DeleteUserAsync(string id)
        {
            var existingUser = await _userRepository.GetUserByIdAsync(id);
            if (existingUser == null) throw new KeyNotFoundException("User not found");
            await _userRepository.DeleteUserAsync(id);
        }
        public async Task<List<User>> GetAllUsersAsync()
        {
            return await _userRepository.GetAllUsersAsync();
        }

        public async Task<User> GetUserByEmailAsync(string email)
        {
            var user = await _userRepository.GetUserByEmailAsync(email);
            if (user == null) throw new KeyNotFoundException("User not found");
            return user;
        }

        public async Task<User> GetUserByIdAsync(string id)
        {
            var user = await _userRepository.GetUserByIdAsync(id);
            if (user == null) throw new KeyNotFoundException("User not found");
            return user;
        }

        public async Task<List<User>> GetUsersByIdsAsync(List<string> ids)
        {
            if (ids == null || ids.Count == 0) return new List<User>();
            return await _userRepository.GetUsersByIdsAsync(ids);
        }

        public async Task<List<User>> GetUsersByPreferencesAsync(User user)
        {
            _ = user.UserPreferences ?? throw new ArgumentException("User preferences not set");
            return await _userRepository.GetUsersByPreferencesAsync(user);
        }

        public async Task UpdateUserAsync(UpdateUserDTO userDto, string id)
        {
            if (id == null) throw new ArgumentException("User ID is required for update");
            var existingUser = await _userRepository.GetUserByIdAsync(id);
            if (existingUser == null) throw new KeyNotFoundException("User not found");

            _mapper.Map(userDto, existingUser);

            await _userRepository.UpdateUserAsync(existingUser);
        }
        public async Task UpdateLocationAsync(string userId, double lat, double lon)
        {
            // Trajno čuvanje u mongo - backup
            await _userRepository.UpdateUserLocationAsync(userId, lat, lon);

            // Upis u Redis - za pretragu
            await _cacheService.UpdateUserLocationAsync(userId, lat, lon);
        }

    }
}