# Product Overview

**Lobe Chat** 🤯 is an open-source, modern-design AI chat framework that supports speech synthesis, multimodal interactions, and an extensible Function Call plugin system.

## Key Features

- **Multi-Model Support**: Supports 42+ AI providers including OpenAI, Anthropic, Google, DeepSeek, Ollama, and more
- **MCP Plugin System**: Model Context Protocol integration for seamless AI-to-world connectivity
- **Desktop & Web**: Available as both web application and desktop app
- **Multimodal**: Vision recognition, text-to-image generation, TTS/STT voice conversations
- **Knowledge Base**: File upload and knowledge base functionality with RAG support
- **Advanced Chat Features**: Chain of Thought visualization, branching conversations, artifacts support
- **Enterprise Ready**: Multi-user management, database support, authentication systems
- **Internationalization**: Support for 20+ languages
- **Self-Hosting**: One-click deployment options with Docker, Vercel, and other platforms

## Target Users

- Individual users seeking a powerful ChatGPT alternative
- Developers building AI applications
- Enterprises requiring self-hosted AI chat solutions
- Teams needing collaborative AI workflows

## Architecture

- **Frontend**: Next.js 15 with React 19, modern UI with Ant Design and @lobehub/ui
- **Backend**: tRPC for type-safe APIs, PostgreSQL with Drizzle ORM
- **State Management**: Zustand with modular slice architecture
- **Desktop**: Electron-based desktop application
- **Database**: Dual database support (PGLite for client, PostgreSQL for server)