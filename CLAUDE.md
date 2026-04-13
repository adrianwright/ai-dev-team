# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AstraTerra AT** is a proof-of-concept Student Information System demonstrating AI-driven agent development on Microsoft Azure. The system manages student records, course registration, academic standing, grades, and advising holds.

### Tech Stack
- **Frontend**: React 19 with React Router 7 (Vite)
- **Backend**: .NET 10 REST API (EF Core)
- **Compute**: Azure Container Apps
- **Data**: Azure SQL (primary), Azure Cosmos DB (NoSQL patterns)
- **Auth**: Microsoft Entra ID (Easy Auth, single-tenant)
- **Infrastructure**: Terraform with Azure Provider 4.x

## Essential Commands

### Backend (.NET 10 API)

```bash
# From src/api/AstraTerra.Api/
dotnet run                          # Run API locally (http://localhost:5000)
dotnet build                        # Build solution
dotnet test                         # Run unit tests
dotnet user-secrets set "<key>" "<value>"  # Store secrets locally
dotnet ef migrations add <Name>     # Create EF Core migration
dotnet ef database update           # Apply migrations to local DB
```

### Frontend (React + Vite)

```bash
# From src/web/
npm install                         # Install dependencies
npm run dev                         # Start dev server (http://localhost:5173)
npm run build                       # Build for production
npm run preview                     # Preview production build locally
```

### Infrastructure (Terraform)

```bash
# From infra/terraform/
terraform init                      # Initialize Terraform
terraform plan                      # Preview resource changes
terraform apply                     # Deploy to Azure
terraform destroy                   # Tear down resources
```

### Azure Developer CLI

```bash
azd up                              # Provision infrastructure and deploy app
azd provision                       # Provision infrastructure only
azd deploy                          # Deploy code to existing infrastructure
azd down                            # Remove all resources
```

## Architecture & Code Organization

### Frontend (src/web/)
- **Vite + React 19** with functional components and hooks
- **Radix UI Themes** for design tokens and component primitives
- **React Router 7** for client-side routing
- Mobile-first responsive design with keyboard/a11y support
- No persisted state management yet; data flows from API via fetch

### Backend (src/api/AstraTerra.Api/)
- **Program.cs**: Service registration, middleware pipeline, CORS, health checks
- **Controllers/**: RESTful endpoints (one controller per resource)
- **Services/**: Business logic and orchestration (IDashboardService, IStudentService, etc.)
- **Data/**: AstraTerraDbContext (EF Core), migrations, seeding
- **Health checks** at `/health` with DB context check included
- **Swagger/OpenAPI** enabled in Development
- CORS configured for local dev (`http://localhost:3000`, `http://localhost:5173`)

### Infrastructure (infra/terraform/)
- **main.tf**: Core resources—resource group, Container Apps environment, SQL Server, Container Registry, Application Insights
- **variables.tf**: Input variables (environment_name, location, sql_location, etc.)
- **outputs.tf**: Key outputs (container app URL, SQL endpoint, etc.)
- Naming follows Azure conventions with environment-based tokens: `acr<name><token>`, `aca-backend-<env>-<token>`, etc.
- Uses Terraform locals for consistent naming and tagging

## Key Development Patterns

### .NET 10 API Standards
- **Async all the way**: Endpoints accept `CancellationToken` on I/O operations
- **Error handling**: Return RFC 7807 Problem Details, never raw exceptions
- **Logging**: Use structured logging; include correlation IDs
- **Validation**: Validate at API boundaries; fail fast
- **Health checks**: `/health` endpoint with DB context check
- **Configuration**: Use `appsettings.json` + Environment variables (never hard-code secrets)
- Dependency injection via `builder.Services.AddScoped<IService, Service>()`

### Azure Cosmos DB Access Patterns
When querying Cosmos DB, follow the decision matrix from `.github/copilot-instructions.md`:
1. **Point read** (best): If both `id` and partition key known → `ReadItemAsync<T>()`
2. **Read many** (good): Batch of known (id, partitionKey) pairs → `ReadManyItemsAsync<T>()`
3. **Query** (necessary): Filtering, sorting, unknown IDs → parameterized `GetItemQueryIterator<T>()`
4. **Always use parameterized queries** to prevent injection
5. **Constrain to logical partition** when possible with `QueryRequestOptions.PartitionKey`
6. **Use continuation tokens** for large result sets; never load all into memory
7. **Track RequestCharge** for optimization; log expensive operations

### React Component Structure
- Functional components with hooks only (no class components)
- One component per file, named to match file
- Keep presentation logic separate from data fetching
- Use Radix UI primitives + project design tokens for consistency
- Props validation via TypeScript (no PropTypes)

## Agent-Driven Development

This project uses seven specialized Copilot agents that execute in sequence:

1. **UX Designer** → HTML mockups from legacy specs
2. **Domain Designer** → Design specs and entity relationships
3. **Dev Orchestrator** → Plans full feature implementation
4. **Database Development** → SQL schema, EF Core entities, migrations
5. **API Developer** → Controllers, services, DTOs
6. **UI Developer** → React components wired to real APIs
7. **Security Development** → Auth, hardening, secrets, pre-commit review

Agent definitions: `.github/agents/*.agent.md`  
Visual workflow: `docs/agent-workflow-generic.html`

When implementing features, follow this sequence rather than jumping straight to code.

## Database & Migrations

- **EF Core** targets `net8.0` with nullable reference types enabled
- Connection string: `AstraTerraDb` (read from appsettings.json or environment)
- Migrations stored in `src/api/AstraTerra.Api/Migrations/`
- Always create a migration when schema changes: `dotnet ef migrations add <DescriptiveName>`
- Apply locally before testing: `dotnet ef database update`

## Azure Deployment

**Container Apps**: Backend runs in Azure Container Apps via Dockerfile at `src/api/AstraTerra.Api/Dockerfile`
**Frontend**: React build artifacts served by nginx (see `src/web/nginx.conf`)
**Networking**: Container Apps Environment provides VNET integration; Easy Auth handles authentication
**Monitoring**: Application Insights + Log Analytics Workspace for observability

## Project Conventions

- **Naming**: PascalCase for C# types/members, camelCase for JavaScript/React
- **File structure**: Feature folders with related components grouped together
- **Branch naming**: `feature/xyz`, `fix/abc`, `refactor/def` (pushed to `main` as main branch)
- **Commit messages**: Descriptive, reference issue/feature, keep to present tense ("Add endpoint" not "Added endpoint")
- **Pull requests**: One feature per PR; include brief summary and testing notes

## Important Notes

- **No commits yet**: Repository is freshly initialized for the POC demonstration
- **Infrastructure**: Terraform is the sole IaC method (no Bicep)
- **Secrets management**: Use User Secrets during local dev (`dotnet user-secrets`); use Azure Key Vault in deployed environments
- **CORS**: Development-only policy; must be hardened for production
- **Exception details**: Currently using `UseDeveloperExceptionPage()` for debugging; remove in production
- **Tests**: Not yet scaffolded; when added, follow xUnit pattern with descriptive test names and Arrange-Act-Assert structure

## Cross-References

- Full requirements & UX mockups: `docs/mockups/`, `docs/design/`
- Legacy system reference: `docs/legacy/`
- Instructions for Copilot agents: `.github/instructions/instructions.instructions.md`
- Copilot code standards: `.github/copilot-instructions.md`
- Azure deployment: `azure.yaml` (azd configuration)
