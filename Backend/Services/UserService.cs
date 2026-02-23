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

        public UserService(ICacheService cacheService, IUserRepository userRepository, IMapper mapper)
        {
            _cacheService = cacheService;
            _userRepository = userRepository;
            _mapper = mapper;
        }
        public Task CreateUserAsync(CreateUserDTO userDto)
        {
            _ = _userRepository.GetUserByEmailAsync(userDto.Email).Result ?? throw new ArgumentException("Email already in use");
            var user = _mapper.Map<User>(userDto);
            return _userRepository.CreateUserAsync(user);
        }

        public Task DeleteUserAsync(Guid id)
        {
            _ = _userRepository.GetUserByIdAsync(id).Result ?? throw new KeyNotFoundException("User not found");
            return _userRepository.DeleteUserAsync(id);
        }
        public Task<List<User>> GetAllUsersAsync()
        {
            return _userRepository.GetAllUsersAsync();
        }

        public Task<User> GetUserByEmailAsync(string email)
        {
            _ = _userRepository.GetUserByEmailAsync(email).Result ?? throw new KeyNotFoundException("User not found");
            return _userRepository.GetUserByEmailAsync(email);
        }

        public Task<User> GetUserByIdAsync(Guid id)
        {
            _ = _userRepository.GetUserByIdAsync(id).Result ?? throw new KeyNotFoundException("User not found");
            return _userRepository.GetUserByIdAsync(id);
        }


        public Task<List<User>> GetUsersByPreferencesAsync(User user)
        {
            _ = user.UserPreferences ?? throw new ArgumentException("User preferences not set");
            return _userRepository.GetUsersByPreferencesAsync(user);
        }

        public Task UpdateUserAsync(UpdateUserDTO userDto)
        {
            _ = _userRepository.GetUserByIdAsync(Guid.Parse(userDto.Id)) ?? throw new KeyNotFoundException("User not found");
            var user = _mapper.Map<User>(userDto);
            return _userRepository.UpdateUserAsync(user);
        }

    }
}