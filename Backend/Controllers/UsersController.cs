using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs.User;
using Backend.Models;
using Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _mongoUserService;

        public UsersController(IUserService mongoUserService)
        {
            _mongoUserService = mongoUserService;
        }

        [HttpPost("CreateUser")]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserDTO user)
        {
            await _mongoUserService.CreateUserAsync(user);
            return Ok(user);
        }

        [HttpGet("GetAllUsers")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _mongoUserService.GetAllUsersAsync();
            return Ok(users);
        }
        [HttpGet("GetUser/{id}")]
        public async Task<IActionResult> GetUser(string id)
        {
            var user = await _mongoUserService.GetUserByIdAsync(id);
            if (user == null)
                return NotFound();
            return Ok(user);
        }

        [HttpPut("UpdateUser/{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] UpdateUserDTO updatedUser)
        {
            var existingUser = await _mongoUserService.GetUserByIdAsync(id);
            if (existingUser == null)
                return NotFound();

            await _mongoUserService.UpdateUserAsync(updatedUser, id);

            var savedUser = await _mongoUserService.GetUserByIdAsync(id);
            return Ok(savedUser);
        }
        [HttpDelete("DeleteUser/{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var existingUser = await _mongoUserService.GetUserByIdAsync(id);
            if (existingUser == null)
                return NotFound();

            await _mongoUserService.DeleteUserAsync(id);
            return NoContent();
        }

        [HttpGet("GetUserByEmail")]
        public async Task<IActionResult> GetUserByEmail([FromBody] string email)
        {
            var user = await _mongoUserService.GetUserByEmailAsync(email);
            if (user == null)
                return NotFound();
            return Ok(user);
        }
    }
}