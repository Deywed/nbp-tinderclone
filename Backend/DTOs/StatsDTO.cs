namespace Backend.DTOs
{
    public class AppStatsDTO
    {
        public int TotalUsers { get; set; }
        public List<InterestStatDTO> TopInterests { get; set; } = new();
        public List<GenderStatDTO> GenderDistribution { get; set; } = new();
        public List<AgeDistributionDTO> AgeDistribution { get; set; } = new();
        public List<AverageAgeByGenderDTO> AverageAgeByGender { get; set; } = new();
    }

    public class InterestStatDTO
    {
        public string Interest { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class GenderStatDTO
    {
        public string Gender { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class AgeDistributionDTO
    {
        public string Range { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class AverageAgeByGenderDTO
    {
        public string Gender { get; set; } = string.Empty;
        public double AverageAge { get; set; }
    }
}
