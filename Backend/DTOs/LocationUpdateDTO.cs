using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.DTOs
{
    public record LocationUpdateDTO
    (
        double Latitude,
        double Longitude
    );
}
