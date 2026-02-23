using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using System.Net;

namespace casino_editor.Middleware;

public sealed class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        // 1. Logujemo samo najbitnije
        logger.LogError(exception, "Error: {Message}", exception.Message);

        // 2. Određujemo status kod
        var statusCode = exception switch
        {
            MongoDB.Driver.MongoWriteException ex when ex.WriteError.Category == MongoDB.Driver.ServerErrorCategory.DuplicateKey
                => HttpStatusCode.Conflict,
            KeyNotFoundException => HttpStatusCode.NotFound,
            ArgumentException => HttpStatusCode.BadRequest,
            UnauthorizedAccessException => HttpStatusCode.Unauthorized,
            _ => HttpStatusCode.InternalServerError
        };

        // 3. Kreiramo standardni ProblemDetails (ugrađen u .NET)
        var problemDetails = new ProblemDetails
        {
            Status = (int)statusCode,
            Title = "API Error",
            Detail = exception.Message,
            Instance = $"{httpContext.Request.Method} {httpContext.Request.Path}"
        };

        // 4. Slanje odgovora
        httpContext.Response.StatusCode = problemDetails.Status.Value;
        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

        return true;
    }
}