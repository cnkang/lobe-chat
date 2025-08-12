# Technology Stack

## Core Framework
- **Next.js 15**: App Router (not Pages Router), React Server Components
- **React 19**: Hooks, functional components, latest features
- **TypeScript**: Strict type checking, latest version
- **Node.js**: Latest LTS version
- **Package Manager**: pnpm (not npm or yarn)

## Frontend Stack
- **UI Framework**: Ant Design + @lobehub/ui design system
- **Styling**: antd-style (CSS-in-JS), supports dark mode and mobile
- **Layout**: react-layout-kit for flex layouts
- **Icons**: lucide-react, @ant-design/icons, @lobehub/icons for AI providers
- **Animation**: @formkit/auto-animate for list animations
- **Internationalization**: react-i18next with 20+ language support

## State Management & Data
- **Global State**: Zustand with modular slice architecture
- **URL State**: nuqs for type-safe search params
- **Data Fetching**: SWR for React data fetching
- **Backend API**: tRPC for type-safe client-server communication
- **Database**: 
  - Client: PGLite (embedded PostgreSQL)
  - Server: PostgreSQL with Drizzle ORM
- **Validation**: Zod for runtime type validation

## Desktop Application
- **Framework**: Electron with electron-vite
- **IPC**: Custom packages (@lobechat/electron-client-ipc, @lobechat/electron-server-ipc)
- **Auto-updater**: electron-updater

## Development Tools
- **Testing**: Vitest + @testing-library/react
- **Linting**: ESLint with @lobehub/lint config
- **Formatting**: Prettier
- **Type Checking**: TypeScript compiler
- **Git Hooks**: Husky + lint-staged

## Utilities
- **Date/Time**: dayjs
- **Utilities**: lodash-es, ahooks (React hooks)
- **Deep Comparison**: fast-deep-equal
- **File Processing**: Various loaders in @lobechat/file-loaders

## Common Commands

```bash
# Development
pnpm dev                    # Start development server (port 3010)
pnpm dev:desktop           # Start desktop development (port 3015)

# Building
pnpm build                 # Build for production
pnpm build:electron        # Build for desktop app
pnpm build:docker          # Build Docker image

# Database
pnpm db:generate           # Generate database schema and client
pnpm db:migrate            # Run database migrations
pnpm db:studio             # Open Drizzle Studio

# Testing & Quality
pnpm test                  # Run all tests
pnpm test-app              # Run app tests only
pnpm test-server           # Run server tests only
pnpm type-check            # TypeScript type checking
pnpm lint                  # Run all linting (TS, style, circular deps)

# Internationalization
pnpm i18n                  # Update translations
pnpm docs:i18n             # Update documentation translations

# Desktop Development
pnpm desktop:build         # Build desktop app
pnpm desktop:build-local   # Build desktop app locally (no signing)
```

## Environment Setup
- Use latest Node.js LTS
- Install pnpm globally: `npm install -g pnpm`
- For desktop development: Additional Electron dependencies
- Database: PostgreSQL for server, PGLite auto-installed for client

## Build Targets
- **Web**: Supports latest browsers only
- **Desktop**: Cross-platform (Windows, macOS, Linux)
- **Docker**: Multi-stage builds with optimization
- **Deployment**: Vercel, self-hosted, or containerized