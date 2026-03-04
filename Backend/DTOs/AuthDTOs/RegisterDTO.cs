using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;
using Backend.Enum;
using Backend.Models;

namespace Backend.DTOs.AuthDTOs
{
    public record RegisterDTO
    (
        [Required]
        [EmailAddress(ErrorMessage = "Neispravan format email adrese.")]
        string Email,

        [Required]
        [MinLength(5, ErrorMessage = "Lozinka mora imati barem 5 karaktera.")]
        string Password,
        [Required]
        string ConfirmPassword,

        [Required(ErrorMessage = "Ime je obavezno.")]
        string FirstName,

        [Required(ErrorMessage = "Prezime je obavezno.")]
        string LastName,

        [Range(18, 100, ErrorMessage = "Morate imati najmanje 18 godina.")]
        int Age,

        string Bio,

        [Required]
        GenderEnum Gender,

        [Required]
        int MinAgePref,

        [Required]
        int MaxAgePref,

        [Required]
        GenderEnum InterestedIn
    );
}
