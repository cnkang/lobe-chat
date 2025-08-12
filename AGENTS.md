# Lobe Chat Codex Agent 指南

本指南为在本仓库中工作的 ChatGPT Codex agent 提供操作规范与最佳实践。

## 🧭 必读资料
在开始前，请先了解以下文档以掌握项目背景与结构：
- [`.kiro/steering/product.md`](.kiro/steering/product.md) – 产品目标与核心功能
- [`.kiro/steering/tech.md`](.kiro/steering/tech.md) – 技术栈、开发工具及常用命令
- [`.kiro/steering/structure.md`](.kiro/steering/structure.md) – 目录组织方式与命名规范

## ⚙️ 工作流程
1. 使用 `pnpm` 运行命令，搜索使用 `rg`，避免 `ls -R` / `grep -R`。
2. 修改前理解相关模块，保持 TypeScript 类型安全与模块边界。
3. 提交前必须运行以下检查并确保通过：
   ```bash
   pnpm lint
   pnpm type-check
   pnpm test
   pnpm build
   ```
4. 使用小而清晰的提交，遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范。

## 🧱 代码约定
- 架构：Next.js 15 + React 19，按功能模块组织。
- 状态：`src/store` 采用 Zustand 切片与选择器对象模式；使用 `immer` 保持不可变更新。
- 组件：必要时使用 `memo` / `useCallback` 优化；为组件设置 `displayName`。
- 类型与数据：使用 Zod 进行运行时校验，避免 `any` 与不安全断言。
- 日志：通过 `@/libs/logger` 输出结构化日志，勿泄露敏感信息。

## 🧪 测试
- 单元与集成测试使用 Vitest：`pnpm test` 或 `npx vitest run <pattern>`。
- 编写选择器、组件及服务的测试用例，确保核心行为可验证。

## 🚀 发布与运维
- 预发布执行 `pnpm lint && pnpm type-check && pnpm test && pnpm build`。
- 数据库迁移：
  ```bash
  MIGRATION_DB=1 pnpm db:migrate
  ```
- 生产问题优先回滚，再进行热修复并监控 Sentry。

## ✅ 工作原则
1. **安全第一**：保护用户数据与体验。
2. **渐进式修改**：每次改动保持原子性，便于回溯。
3. **测试驱动**：修改前后均运行相关测试。
4. **文档同步**：代码变更需更新相应文档。
5. **及时求助**：遇到不确定性时向团队寻求帮助。

欢迎遵循以上准则，共同维护并持续改进 Lobe Chat。
