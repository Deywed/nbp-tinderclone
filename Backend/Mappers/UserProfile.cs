using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;

namespace Backend.Mappers
{
    public class UserProfile : Profile
    {
        public UserProfile()
        {
            CreateMap<DTOs.User.CreateUserDTO, Models.User>();
            CreateMap<DTOs.User.UpdateUserDTO, Models.User>();
        }
    }
}