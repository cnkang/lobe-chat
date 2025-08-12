# Project Structure

## Monorepo Organization
```
├── apps/
│   └── desktop/           # Electron desktop application
├── packages/              # Shared packages
│   ├── electron-client-ipc/
│   ├── electron-server-ipc/
│   ├── file-loaders/
│   ├── types/
│   └── web-crawler/
├── src/                   # Main web application source
├── docs/                  # Documentation
├── locales/               # Internationalization files
└── scripts/               # Build and workflow scripts
```

## Main Application Structure (`src/`)

### Core Directories
- **`app/`**: Next.js App Router pages and API routes
  - `(backend)/`: Server-side API routes
  - `[variants]/`: Dynamic routing for different app variants
  - `desktop/`: Desktop-specific pages
- **`components/`**: Reusable UI components
- **`features/`**: Feature-specific components and logic
- **`store/`**: Zustand state management with modular slices
- **`database/`**: Database schemas, migrations, and repositories
- **`services/`**: Business logic and external API integrations

### Supporting Directories
- **`hooks/`**: Custom React hooks
- **`utils/`**: Utility functions and helpers
- **`types/`**: TypeScript type definitions
- **`config/`**: Configuration files and constants
- **`libs/`**: Third-party library integrations
- **`styles/`**: Global styles and theme configurations
- **`locales/`**: Internationalization resources

## Key Architectural Patterns

### Zustand Store Organization
```
src/store/[storeName]/
├── slices/
│   └── [sliceName]/
│       ├── actions/       # Complex actions (optional subdirectory)
│       ├── action.ts      # Slice actions
│       ├── initialState.ts # State interface and defaults
│       ├── selectors.ts   # State selectors (export as xxxSelectors)
│       └── reducer.ts     # Pure state reducers (optional)
├── initialState.ts        # Aggregated initial state
├── store.ts              # Main store definition
├── selectors.ts          # Aggregated selectors
└── helpers.ts            # Store helper functions
```

### Component Organization
- **Atomic Design**: Components organized by complexity level
- **Feature-based**: Related components grouped in `features/`
- **Shared Components**: Reusable components in `components/`
- **Server Components**: RSC components in `components/server/`

### Database Structure
```
src/database/
├── schemas/              # Drizzle schema definitions
├── migrations/           # Database migration files
├── repositories/         # Data access layer
├── client/              # Client-side database (PGLite)
├── server/              # Server-side database utilities
└── models/              # Business logic models
```

## File Naming Conventions

### Components
- **React Components**: PascalCase (e.g., `ChatInput.tsx`)
- **Component Directories**: PascalCase with index file
- **Hooks**: camelCase starting with `use` (e.g., `useChat.ts`)

### Store Files
- **Slices**: camelCase directory names (e.g., `message/`, `aiChat/`)
- **Actions**: `action.ts` or `actions/` directory for complex cases
- **Selectors**: Export as `xxxSelectors` object pattern
- **State**: `initialState.ts` with interface and defaults

### Utilities and Services
- **Services**: camelCase (e.g., `chatService.ts`)
- **Utils**: camelCase (e.g., `formatMessage.ts`)
- **Constants**: camelCase files, UPPER_CASE exports

## Import Path Conventions
- **Absolute Imports**: Use `@/` for src directory
- **Type Imports**: Use `@/types/` for shared types
- **Explicit Index**: Prefer `@/db/index` over `@/db`
- **Package Imports**: Use workspace references for monorepo packages

## Directory-Specific Rules

### `features/` Directory
- Each feature is self-contained with its own components, hooks, and logic
- Features can have their own types and utilities
- Cross-feature dependencies should be minimal

### `services/` Directory
- Business logic separated from UI components
- API integrations and external service wrappers
- Stateless functions that can be easily tested

### `database/` Directory
- Schema definitions using Drizzle ORM
- Repository pattern for data access
- Separate client and server database logic

## Configuration Files Location
- **Root Level**: Package management, build tools, deployment
- **`.cursor/rules/`**: AI coding assistance rules
- **`src/config/`**: Application configuration
- **`src/envs/`**: Environment variable validation

## Testing Structure
- **`tests/`**: Global test utilities and setup
- **`__tests__/`**: Co-located with source files
- **`*.test.ts`**: Unit tests alongside source files
- **`*.spec.ts`**: Integration tests

This structure supports the modular, scalable architecture needed for a complex AI chat application while maintaining clear separation of concerns.