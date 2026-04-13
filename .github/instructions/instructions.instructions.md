---
description: AstraTerra AT POC project context, domain overview, and development guidance
applyTo: "src/**"
---

# AstraTerra AT POC — Project Context

## What This Is
A **proof-of-concept Interplanetary Study Abroad Portal** ("AstraTerra") demonstrating AI-driven agent development. The product covers traveler records, program track applications, transit scheduling, portal alerts, and travel holds for TerraFirma Polytechnic. The goal is a modern, streamlined portal-operations experience built by specialized AI agents.

## Product Domains

### Traveler Records
Core traveler data management:
- **Dashboard** — enrollment overview, headcount by program track, portal alerts, travel holds.
- **Traveler Search** — searchable, sortable traveler list with advanced filters.
- **Traveler Record Detail** — tabbed view of demographics, program track, transit schedule, evaluations, holds.

### Program Track Applications
- **Program Search & Application** — search program tracks, apply, waitlist management.
- **Schedule View** — traveler's current transit schedule with credit tracking.

### Portal Operations
- **Transit History** — term-by-term transit history, cumulative progress.
- **Program Audit** — progress toward program track completion requirements.

## UX & Design Direction
- **Legacy reference**: Mockups in `docs/mockups/` show the fictional legacy "ASTRATERRA" interface — a dated, Bootstrap 3-era aesthetic with dark blue branding. These represent the "before" state for the AI agent modernization demo.
- The **modern** UI should use React with clean, consistent design tokens and components.
- Mobile-first, responsive layouts. Keyboard and screen-reader accessible.

## Platform & Infrastructure
- **Cloud**: Microsoft Azure.
- **Authentication**: Microsoft Entra ID (Azure AD).
- **Frontend**: React (`src/web`).
- **Backend**: .NET 10 microservice API (`src/api`).
- **Data store**: Azure SQL Database (primary, via EF Core). Azure Cosmos DB for NoSQL when access patterns demand it.