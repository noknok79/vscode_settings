---
applyTo: "src/services/bff/**/*.cs,src/services/functions/**/*.cs,tests/unit/BFF.Unit.Tests/**/*.cs,tests/integration/BFF.Integration.Tests/**/*.cs"
description: "Apply Clean Architecture, CQRS, ErrorOr, mapping, resilience, and security conventions. Use when: modify BFF domain, application, infrastructure, API, Azure Functions, or related tests."
---

# BFF + Domain Instructions

## Clean Architecture — Strict Dependency Rule

```
API → Application → Domain ← Infrastructure
```

- `Domain` has **zero** external dependencies — no NuGet packages, no EF Core, no Azure SDK.
- `Application` references `Domain` only.
- `Infrastructure` references `Application` + `Domain`; never `API`.
- `API` references `Application` + `Infrastructure` (for DI registration only).

## Adding a New Feature — Checklist

1. **Domain first:** define entity + value objects in `BFF.Domain/`.
2. **Command/Query:** create in `BFF.Application/Commands/` or `BFF.Application/Queries/`.
3. **Validator:** create matching `[Command]Validator.cs` using FluentValidation.
4. **Handler returns `ErrorOr<T>`:** never throw for business failures.
5. **Static mapper:** add to `BFF.Application/Mappings/[Entity]Mapper.cs`.
6. **Controller method:** thin — call `_mediator.Send(command)`, call `result.Match(...)`, return `ApiResponse<T>`.
7. **Integration test:** add to `BFF.Integration.Tests/` using `WebApplicationFactory`.
8. **Unit test:** add to `BFF.Unit.Tests/`.

## ErrorOr Pattern

```csharp
// Handler
public async Task<ErrorOr<ExampleDto>> Handle(CreateExampleCommand request, CancellationToken ct)
{
    var entity = ExampleEntity.Create(request.Title, request.Description);
    if (entity.IsError) return entity.Errors;
    await _repo.AddAsync(entity.Value, ct);
    await _uow.SaveChangesAsync(ct);
    return ExampleMapper.ToDto(entity.Value);
}

// Controller
var result = await _mediator.Send(command, ct);
return result.Match(
    dto => Ok(ApiResponse<ExampleDto>.Success(dto)),
    errors => errors.ToProblemDetails(this));
```

## ApiResponse Envelope

```csharp
// Always use this shape — never return raw types
ApiResponse<T>.Success(data)
ApiResponse<T>.Failure("message")
```

## CQRS Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Command | `[Verb][Entity]Command` | `CreatePlanCommand` |
| Query | `Get[Entity]By[Key]Query` | `GetPlanByIdQuery` |
| Handler | `[Command/Query]Handler` | `CreatePlanCommandHandler` |
| Validator | `[Command/Query]Validator` | `CreatePlanCommandValidator` |
| DTO | `[Entity]Dto` | `PlanDto` |
| Mapper | `[Entity]Mapper` | `PlanMapper` (static class, static methods) |

## Security Rules

- Never use `IConfiguration` directly in handlers — inject `IOptions<T>` typed settings.
- Never log sensitive fields (tokens, passwords, connection strings).
- Always inject `ICurrentUserService` for user context; never read JWT claims directly in handlers.
- `DefaultAzureCredential` only — no connection strings.

## Service Bus Publishing

```csharp
// Publish after SaveChangesAsync — fire and forget, never await CRM
await _publisher.PublishAsync("orders", new OrderCreatedMessage { ... }, ct);
```

## EF Core Rules

- Use `EnableRetryOnFailure(3, TimeSpan.FromSeconds(5))` + `CommandTimeout(180)` — wired in `BffDbContext`/`CuratedReadDbContext` (both interactive-only in this repo). SQL connection timeout is set to 180 seconds by `PasswordlessSqlConnection.Validate`.
- Concurrency: `[Timestamp]` / `byte[] RowVersion` on all entities.
- No raw SQL in handlers — use `IRepository<T>.Query()` or EF LINQ.

## Settings Injection Pattern

```csharp
// Infrastructure/Configuration/BffSettings.cs
public sealed class BffSettings
{
    public bool UseInMemoryStore { get; init; }
    public string DataSource { get; init; } = "InMemory";
}

// Usage
public MyService(IOptions<BffSettings> opts) { _settings = opts.Value; }
```
