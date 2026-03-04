namespace Backend.DTOs
{
    public class TopPickResponseDTO
    {
        public Backend.Models.User User { get; set; } = null!;
        public int LikeCount { get; set; }
    }
}
