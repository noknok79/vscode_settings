---
applyTo: "tests/**/*.cs"
description: "Align unit and integration tests with the canonical test plan and repository conventions. Use when: add tests, modify tests, map requirement scenarios, or investigate test coverage gaps."
---

# Test Instructions

## Required Test-Plan Alignment

Before implementing or modifying a unit or integration test, read the relevant Markdown test-plan documents from:

- `docs/Solution/Overview/Testing/INDEX.md` — test-plan structure, feature areas, and test-pyramid mapping.
- The matching `docs/Solution/Overview/Testing/PID26-*.md` document — requirement IDs, detailed scenarios, preconditions, expected behavior, and validation considerations for the affected endpoint or workflow.

The repository-local `docs/Solution/Overview/Testing/` folder is the canonical detailed test plan.

The test plan is a design input, not optional background reading. For every new or changed test:

1. Identify the requirement ID, feature area, and test-plan scenario being covered.
2. Preserve the plan's preconditions, expected result, state-transition rules, and negative/edge-case intent.
3. Add or update coverage for the plan's applicable positive, negative, boundary, authorization, and persistence behavior.
4. If implementation and plan disagree, pause the test change long enough to document the discrepancy and confirm the intended contract; do not encode an undocumented assumption.
5. Report the requirement/scenario mapping and any uncovered plan cases with the test results.

## Test Pyramid

```
Integration (xUnit)        ← every API endpoint
Unit (xUnit)               ← all business logic
```

## Coverage Policy

The enforceable minimums are 70% for business logic and 60% overall, excluding generated and EF scaffolding code. Higher targets are expected for focused areas: 100% for domain invariants and validators, 90% for application handlers, and complete endpoint coverage through integration tests.

## BFF Unit Tests (xUnit)

- **Location:** `tests/unit/BFF.Unit.Tests/`
- **Naming:** `[Class]Tests.cs` → test method `[Method]_[Scenario]_[ExpectedResult]`
- **Mocking:** use `NSubstitute` (already referenced)
- **Assertions:** use `FluentAssertions`
- **Pattern:** Arrange / Act / Assert with blank lines between sections

```csharp
[Fact]
public async Task Handle_ValidCommand_ReturnsDtoWithCorrectTitle()
{
    // Arrange
    var repo = Substitute.For<IRepository<ExampleEntity>>();
    var uow = Substitute.For<IUnitOfWork>();
    var handler = new CreateExampleCommandHandler(repo, uow);
    var command = new CreateExampleCommand("Test Title", "Description");

    // Act
    var result = await handler.Handle(command, CancellationToken.None);

    // Assert
    result.IsError.Should().BeFalse();
    result.Value.Title.Should().Be("Test Title");
}
```

## BFF Integration Tests (xUnit + WebApplicationFactory)

- **Location:** `tests/integration/BFF.Integration.Tests/`
- **Factory:** use existing `InDispensableWebApplicationFactory` — sets `UseInMemoryStore: true` automatically.
- **Auth:** DevBypass is active — no token required in tests.
- **Naming:** `[Controller]IntegrationTests.cs`
- Never call real Azure services in integration tests.

```csharp
[Fact]
public async Task POST_Plans_Returns201_WithValidPayload()
{
    // Arrange
    var client = _factory.CreateClient();
    var payload = new CreatePlanRequest { ... };

    // Act
    var response = await client.PostAsJsonAsync("/api/v1/plans", payload);

    // Assert
    response.StatusCode.Should().Be(HttpStatusCode.Created);
    var body = await response.Content.ReadFromJsonAsync<ApiResponse<PlanDto>>();
    body!.IsSuccess.Should().BeTrue();
}
```

## Coverage Targets

| Layer | Target |
|-------|--------|
| Domain entities (business logic methods) | 100% |
| Application handlers | 90%+ |
| API controllers (via integration tests) | 100% of endpoints |

## What NOT to Test

- EF Core internals (library code)
- Azure SDK calls (mock at the interface boundary)
- DTOs / plain data containers with no logic
- Generated code
