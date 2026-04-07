# GitHub Copilot Instructions - AI Dev Team

## Purpose
These instructions define how Copilot should generate and modify code in this repository.

The solution is a full-stack application with:
- React frontend.
- .NET 10 backend services using microservice API best practices.
- Azure Cosmos DB for NoSQL as the operational data store.

## Project Defaults
- Prefer small, incremental, production-leaning changes over large rewrites.
- Keep generated code consistent with existing structure under `src/web` and `src/api`.
- Keep security, observability, and testability as first-class requirements.

## Frontend Standards (React)

- Use React patterns (functional components, hooks, composition) and keep components focused.
- Use consistent spacing, typography, and color tokens.
- Prefer reusable components over custom CSS.
- Build responsive layouts (mobile-first) and maintain keyboard/screen-reader support.
- Keep business logic out of presentation components where practical.

## Backend Standards (.NET 10 Microservice API)

- Target `.NET 10` (`net10.0`) for new backend work and upgrades.
- Use async all the way and accept `CancellationToken` on I/O-bound endpoints.
- Design APIs around clear resource boundaries and versioning readiness.
- Return RFC 7807 problem details for errors; do not return raw exceptions.
- Use descriptive variable, class, and method names that convey intent.
- Include:
  - health checks (`/health`),
  - structured logging,
  - distributed tracing (OpenTelemetry-ready),
  - correlation IDs.
- Validate requests at API boundaries and fail fast on invalid inputs.
- Keep business rules in domain/service layers, not endpoint glue code.
- Keep containerized runtime and configuration twelve-factor friendly.
- Protect secrets via configuration providers (never hard-code secrets).

## Azure Cosmos DB Guidance (Microsoft Best Practices)

Use the lowest-RU, lowest-latency read pattern that satisfies the access pattern.

### Query Method Decision Matrix

1. If both `id` and partition key are known for one item:
   Use point read: `ReadItemAsync<T>()`.
   This is the most efficient read pattern.

2. If many known (`id`, partitionKey) pairs are needed:
   Use `ReadManyItemsAsync<T>()`.
   Prefer this over query-with-IN for fetching many known items.

3. If filtering, sorting, aggregating, searching, or unknown IDs are required:
   Use query iterator with SQL query:
   `GetItemQueryIterator<T>(QueryDefinition, requestOptions)`.

4. For all SQL-style queries:
   Use parameterized queries (`QueryDefinition.WithParameter`) to avoid injection and improve safety.

5. When query scope can be constrained to one logical partition:
   Set `QueryRequestOptions.PartitionKey`.
   Avoid cross-partition fan-out unless required by the use case.

6. For large result sets:
   Use continuation-token paging via feed iterators; do not load all results into memory.

### Data Modeling and RU Optimization Rules

- Design partition keys around dominant query and write access patterns (high cardinality, even distribution).
- Shape item `id` and partition key to maximize point-read usage on hot paths.
- Only index fields that are queried; tune indexing policy for production workloads.
- Use projections for queries instead of `SELECT *` when full documents are not required.
- Track and log `RequestCharge` and diagnostics for expensive operations.
- Remember consistency impact: strong or bounded staleness doubles read RU cost.

### SDK and Runtime Rules

- Register `CosmosClient` as a singleton for app lifetime.
- Prefer direct mode for performance-sensitive production workloads.
- Configure preferred regions close to compute.
- Use latest stable Azure Cosmos DB .NET SDK.
- Keep Cosmos operations fully async; avoid `.Result`/`.Wait()`.

## Implementation Expectations

- For each new repository/service method, choose and document the Cosmos access pattern (point read, read-many, or query) in code comments or PR notes when non-obvious.
- New endpoints should define expected partition key behavior explicitly.
- Add or update tests for happy path, validation failures, and not-found behavior.

## Definition of Done for Generated Changes

- Frontend changes follow project conventions and use consistent design tokens.
- Backend changes are `.NET 10` compatible and microservice-safe.
- Cosmos data access uses the best-fit method from the matrix above.
- Logging and error handling follow production-ready conventions.
- Build and tests pass for touched projects.
