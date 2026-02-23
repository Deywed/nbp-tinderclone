using System.Text;
using Backend.Hubs;
using Backend.Services;
using Backend.Services.Interfaces;
using Backend.Services.Neo4J;
using Backend.Services.Redis;
using casino_editor.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MongoDB.Driver;
using Neo4j.Driver;
using Scalar.AspNetCore;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// --- SERVISI ---

// 1. Dodaj kontrolere
builder.Services.AddControllers();

// 2. Swagger/OpenAPI - KORISTI SAMO OVO ZA SWAGGER UI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Moj API", Version = "v1" });

    // Definisanje Security šeme
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Unesi token ovako: Bearer {tvoj_token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 3. Baze

//MongoDB
var mongoConnectionString = builder.Configuration.GetConnectionString("MongoDb");
builder.Services.AddSingleton<IMongoClient>(new MongoClient(mongoConnectionString));

//NEO4j
var neo4jUri = builder.Configuration.GetConnectionString("Neo4j");
var neo4jUser = builder.Configuration["Neo4jSettings:User"];
var neo4jPass = builder.Configuration["Neo4jSettings:Password"];
builder.Services.AddSingleton(GraphDatabase.Driver(neo4jUri, AuthTokens.Basic(neo4jUser, neo4jPass)));

var redisConnectionString = builder.Configuration.GetSection("Redis:ConnectionString").Value;

// Registracija ConnectionMultiplexer-a kao Singleton (to je preporuka za Redis)
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
    ConnectionMultiplexer.Connect(redisConnectionString!));

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();


// 4. Servsi
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<ISwipeService, Neo4JService>();
builder.Services.AddScoped<ICacheService, RedisService>();

builder.Services.AddSignalR();

// 2. Podesi CORS (MORAŠ dozvoliti Credentials zbog SignalR-a)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy.WithOrigins("http://localhost:XXXXX") // Port tvog Fluttera
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); // Obavezno za SignalR!
    });
});

// 5. JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
// Konfiguracija JWT
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(
        Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key nije pronađen u konfiguraciji"))),
    };
});





var app = builder.Build();

// --- MIDDLEWARE ---

if (app.Environment.IsDevelopment())
{

    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("Casino Editor API")
               .WithTheme(ScalarTheme.DeepSpace)
               .WithDefaultHttpClient(ScalarTarget.CSharp, ScalarClient.HttpClient);
    });
}
app.UseCors("AllowFlutter");

// 3. Mapiraj rutu za Hub
app.MapHub<MatchHub>("/matchHub");
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.UseExceptionHandler();

app.Run();