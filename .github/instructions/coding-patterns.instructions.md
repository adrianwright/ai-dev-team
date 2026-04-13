---
description: "Use when: writing C# classes, React components, EF Core queries, or LINQ expressions. Covers OOP design, React composition, and Entity Framework data access patterns for the AstraTerra codebase."
applyTo: "src/**"
---

# Coding Patterns — OOP, React & EF Core

## Object-Oriented Design

### Class Responsibilities
- **Controllers** are thin — validate input, delegate to a service, return the result. No business logic, no direct DbContext usage.
- **Services** own business rules and orchestration. One service per domain aggregate (e.g., `ICaseService`, `IStudentService`).
- **Entities** are plain POCO classes representing database rows. No methods that call infrastructure.
- **DTOs** are separate from entities. Never return an entity directly from a controller.

### Interface Contracts
- Every service has an interface (`IXxxService`) registered via `AddScoped<IXxxService, XxxService>()`.
- Depend on abstractions (interfaces), not concrete classes. Controllers and services accept interfaces through constructor injection.
- Keep interfaces focused — split large interfaces rather than adding unrelated methods.

### Naming & Structure
- One class per file; filename matches class name.
- Private fields: `_camelCase`. Parameters and locals: `camelCase`. Types and members: `PascalCase`.
- Group by layer: `Controllers/`, `Services/`, `Entities/`, `DTOs/`, `Data/`.

### Inheritance & Composition
- Prefer composition over inheritance. Inject collaborators rather than subclassing.
- Use `sealed` on classes that are not designed for extension.
- Avoid static helper classes for testability; use injected services instead.

---

## React Patterns

### Component Design
- Functional components only. One component per file, PascalCase name matching the filename.
- Keep components small and focused — split when a component handles more than one concern.
- Presentation components receive data via props. They do not fetch data or manage side effects.

### Custom Hooks for Data Fetching
- Extract all `fetch` calls and async logic into custom hooks under `hooks/` (e.g., `useStudents`, `useCaseDetail`).
- Hooks return `{ data, loading, error }` so components render all three states consistently.
- Call the API service layer (`services/api.js`) from hooks, not from components directly.

```jsx
// hooks/useStudents.js
export function useStudents() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.getStudents()
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, []);

  return { data, loading, error };
}
```

### State & Props
- Lift state to the nearest common ancestor — no prop drilling beyond two levels. Use context or composition instead.
- Derive values during render rather than syncing with extra state.
- Memoize expensive computations with `useMemo`; memoize callbacks with `useCallback` only when passed to child components that depend on reference equality.

### Styling
- Use Radix UI Themes components and design tokens. Do not create new CSS files.
- Use the CSS variables defined in `styles.css` (e.g., `--blue-700`, `--gray-50`, `--radius`).

---

## EF Core Query Patterns

### Projection & DTOs
- Always `.Select()` into a DTO or anonymous type. Never load full entities when only a subset of fields is needed.
- **Never use record/class constructors inside `.Select()` after `.GroupBy()`** — EF Core cannot translate them. Project to an anonymous type, call `ToListAsync()`, then map to DTOs in memory.

```csharp
// CORRECT — anonymous type first, then map
var groups = await _db.Enrollments
    .GroupBy(e => e.ProgramTrack)
    .Select(g => new { Track = g.Key, Count = g.Count() })
    .ToListAsync(cancellationToken);

var result = groups.Select(g => new TrackSummaryDto(g.Track, g.Count)).ToList();
```

### Tracking
- Use `.AsNoTracking()` on all read-only queries (dashboards, search, detail views).
- Only use tracked queries when you intend to modify and save the entity.

### Async & CancellationToken
- All EF calls use async materializers: `ToListAsync`, `FirstOrDefaultAsync`, `CountAsync`, etc.
- Pass `CancellationToken` from controller → service → EF call. Never omit it on I/O methods.

### Filtering & Sorting
- Build queries incrementally with `IQueryable`. Apply filters conditionally, then materialize once.
- Use parameterized values — never interpolate user input into raw SQL.

```csharp
IQueryable<Student> query = _db.Students.AsNoTracking();

if (!string.IsNullOrEmpty(search))
    query = query.Where(s => s.LastName.Contains(search));

if (programTrackId.HasValue)
    query = query.Where(s => s.ProgramTrackId == programTrackId.Value);

return await query
    .OrderBy(s => s.LastName)
    .Select(s => new StudentListDto { Id = s.Id, Name = s.FullName })
    .ToListAsync(cancellationToken);
```

### Navigation Properties
- Use `.Include()` explicitly when related data is needed. Never rely on lazy loading.
- For complex queries needing data from multiple tables, prefer separate focused queries over deep Include chains.

### Pagination
- Use `Skip`/`Take` for offset pagination on list endpoints. Accept `page` and `pageSize` parameters with sensible defaults and upper bounds.
