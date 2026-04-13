You are building a full-stack application from a UX mockup. Follow these phases in order, delegating each to a specialized agent.

## Phase 1: UX Mockup
Create a self-contained HTML mockup in docs/mockups/ as a NEW file (don't overwrite originals). Use:
- Pure CSS/SVG for charts (no JS libraries)
- Realistic placeholder data matching the domain
- Responsive layout, modern typography (Inter), consistent color theme
- All styles inline in <style> block — single file, no dependencies beyond Google Fonts

## Phase 2: Database Scripts
Delegate to a database agent. Provide it:
- The exact table schemas derived from entity classes (read them first)
- Seed data extracted from the mockup (student names, IDs, statuses, alert details)
- Rules: idempotent SQL (IF NOT EXISTS guards), fixed GUIDs (no NEWID()), DATETIMEOFFSET timestamps

Output: scripts/001-create-tables.sql, scripts/002-seed-data.sql

## Phase 3: API Layer
Delegate to an API agent. Provide it:
- Entity classes and DbContext (read them first)
- The exact endpoints the UI will need, derived from the mockup widgets
- DTO shapes matching what the frontend expects
- Rules: async/await, EF Core .Select() projections, .AsNoTracking(), paginated search with dynamic filters

Output: Services (interface + implementation), Controllers, DTOs, Program.cs service registrations

## Phase 4: React UI
Delegate to a UI agent. Provide it:
- Existing scaffold (read App.jsx, main.jsx, layout, api service, hooks)
- List of MISSING component files only — don't overwrite existing ones
- Data shapes from the API (field names, types)
- Rules: pure CSS/SVG charts (no chart libraries), CSS files for styling, functional components

Output: Missing page components, CSS files, barrel index.js files

## Phase 5: Restyle to Match Mockup
Delegate to a UI agent. Provide it:
- The FULL content of the HTML mockup (read it and include in prompt)
- The FULL content of each React component to be restyled (read them)
- Specific differences: layout structure, color palette, nav pattern, typography
- Rules: read before modifying, don't break routing, preserve data-fetching logic

Output: Updated AppShell, CSS files, component tweaks

## Key Principles
1. ALWAYS read existing files before creating or modifying — don't guess at schemas, DTOs, or component structure
2. Create new files rather than overwriting originals for mockups
3. Agent prompts must include complete context — schemas, data shapes, file paths, styling specs. Agents don't see the conversation history.
4. API base URL should default to '/api' (relative) for deployment compatibility; use Vite proxy for local dev
5. Connection strings come from config, never hardcoded
6. Add an obvious visual identifier (version badge) to confirm the new UI is rendering
7. Run phases sequentially — each depends on the prior phase's output
8. After all phases, verify end-to-end: start API, start frontend, confirm data flows from DB → API → UI