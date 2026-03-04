using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs.User;
using Backend.Models;
using Backend.Repositories.Interfaces;
using MongoDB.Driver;

namespace Backend.Repositories
{
    public class MongoUserRepository : IUserRepository
    {
        private readonly IMongoCollection<User> _users;
        public MongoUserRepository(IMongoDatabase database)
        {
            _users = database.GetCollection<User>("Users");
        }
        public async Task CreateUserAsync(User user)
        {
            await _users.InsertOneAsync(user);
        }

        public async Task DeleteUserAsync(string id)
        {
            await _users.DeleteOneAsync(u => u.Id == id.ToString());
        }

        public async Task<List<User>> GetAllUsersAsync()
        {
            return await _users.Find(_ => true).ToListAsync();
        }

        public async Task<User> GetUserByEmailAsync(string email)
        {
            return await _users.Find(u => u.Email == email).FirstOrDefaultAsync();
        }

        public async Task<User> GetUserByIdAsync(string id)
        {
            return await _users.Find(u => u.Id == id).FirstOrDefaultAsync();
        }

        public async Task<List<User>> GetUsersByPreferencesAsync(User user)
        {
            var builder = Builders<User>.Filter;

            var filter = builder.And(
                builder.Ne(u => u.Id, user.Id),
                builder.Gte(u => u.Age, user.UserPreferences.MinAgePref),
                builder.Lte(u => u.Age, user.UserPreferences.MaxAgePref),
                builder.Eq(u => u.Gender, user.UserPreferences.InterestedIn)
            );
            return await _users.Find(filter).ToListAsync();
        }

        public async Task<List<User>> GetUsersByGender(User user)
        {
            return await _users.Find(u => u.Gender == user.Gender).ToListAsync();
        }

        public async Task UpdateUserAsync(User user)
        {
            await _users.ReplaceOneAsync(u => u.Id == user.Id.ToString(), user);
        }
        public async Task UpdateUserLocationAsync(string userId, double lat, double lon)
        {
            var filter = Builders<User>.Filter.Eq(u => u.Id, userId);
            var update = Builders<User>.Update.Set(u => u.LastLocation, new UserLocation
            {
                Type = "Point",
                Coordinates = new List<double> { lon, lat }
            });

            await _users.UpdateOneAsync(filter, update);
        }

        public async Task<List<User>> GetUsersByIdsAsync(List<string> ids)
        {
            if (ids == null || ids.Count == 0) return new List<User>();
            var filter = Builders<User>.Filter.In(u => u.Id, ids);
            return await _users.Find(filter).ToListAsync();
        }
    }
}