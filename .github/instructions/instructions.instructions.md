---
description: AI Dev Team project context and development guidance
applyTo: "src/**"
---

# AI Dev Team — Project Context

## What This Is
A repository demonstrating **AI-driven agent development** using specialized AI agents to plan, build, and maintain a full-stack application. The goal is to showcase how multiple purpose-built agents collaborate across domains — from UX design and frontend development to API implementation, database design, and security.

## UX & Design Direction
- Mockups in `docs/mockups/` provide reference designs for the target application.
- The UI should use React with clean, consistent design tokens and components.
- Mobile-first, responsive layouts. Keyboard and screen-reader accessible.

## Platform & Infrastructure
- **Cloud**: Microsoft Azure.
- **Authentication**: Microsoft Entra ID (Azure AD).
- **Frontend**: React (`src/web`).
- **Backend**: .NET 10 microservice API (`src/api`).
- **Data store**: Azure SQL Database (primary, via EF Core). Azure Cosmos DB for NoSQL when access patterns demand it.