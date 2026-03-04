using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Enum;
using Backend.Models;

namespace Backend.DTOs.User
{
    public record CreateUserDTO
    (
        string Email,
        string Password,
        string FirstName,
        string LastName,
        int Age,
        string Bio,
        GenderEnum Gender,
        UserPreferences UserPreferences,
        List<string> Interests
    );
}
