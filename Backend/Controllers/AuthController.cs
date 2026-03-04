using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.DTOs.AuthDTOs;
using Backend.DTOs.User;
using Backend.Models;
using Backend.Services;
using Backend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly ITokenService _tokenService;
        private readonly IUserService _userService;
        public AuthController(ITokenService tokenService, IUserService userService)
        {
            _tokenService = tokenService;
            _userService = userService;
        }
        [HttpPost("Login")]
        public async Task<IActionResult> Login([FromBody] LoginDTO loginDTO)
        {
            try
            {
                var user = await _userService.GetUserByEmailAsync(loginDTO.Email);
                if (user == null) return Unauthorized("Invalid email or password");


                bool isPasswordValid = BCrypt.Net.BCrypt.Verify(loginDTO.Password, user.PasswordHash);
                if (!isPasswordValid) return Unauthorized("Invalid email or password");

                var token = _tokenService.GenerateToken(user);
                return Ok(new { Token = token });
            }
            catch (KeyNotFoundException)
            {
                return Unauthorized("Invalid email or password");
            }
        }

        [HttpPost("Register")]
        public async Task<IActionResult> Register([FromBody] CreateUserDTO registerDTO)
        {
            await _userService.CreateUserAsync(registerDTO);
            return Ok("User registered successfully");
        }
    }
}