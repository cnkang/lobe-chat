# ChatGPT Codex Agent 操作指南

## 概述

本文档指导 ChatGPT codex agent 如何有效地操作、维护和修复 Lobe Chat 代码库。作为一个复杂的 AI 聊天应用，需要遵循特定的工作流程和最佳实践。

## 📚 参考文档

在开始操作之前，请先阅读以下 steering 文档以了解项目背景：

- **[.kiro/steering/product.md](.kiro/steering/product.md)** - 产品概述和核心功能
  - 了解 Lobe Chat 是什么，支持哪些功能
  - 目标用户和使用场景
  - 整体架构概览

- **[.kiro/steering/tech.md](.kiro/steering/tech.md)** - 技术栈和开发工具
  - 核心技术框架 (Next.js 15, React 19, TypeScript)
  - 开发工具和常用命令
  - 环境设置和构建流程

- **[.kiro/steering/structure.md](.kiro/steering/structure.md)** - 项目结构和组织方式
  - 代码目录结构和命名规范
  - Zustand store 的模块化架构
  - 组件组织和导入路径约定

**重要提示**：在进行任何代码修改之前，务必先理解这些基础文档，它们提供了项目的核心上下文。

## 代码库理解原则

### 1. 架构优先

- **始终先理解整体架构**：这是一个 Next.js 15 + React 19 的现代化应用
- **模块化设计**：代码按功能模块组织，避免跨模块的强耦合修改
- **类型安全**：所有修改必须保持 TypeScript 类型安全

### 2. 状态管理模式

- **Zustand 切片架构**：理解 `src/store/` 下的模块化状态管理
- **选择器模式**：使用 `xxxSelectors` 对象导出选择器
- **不可变更新**：使用 immer 进行状态更新

## 常见问题诊断流程

### 🔍 问题分析步骤

1. **确定问题范围**

   ```bash
   # 检查类型错误
   pnpm type-check
   
   # 运行相关测试
   npx vitest run --config vitest.config.ts '[相关文件模式]'
   ```

2. **定位问题模块**
   - 前端问题：检查 `src/components/`, `src/features/`
   - 状态问题：检查 `src/store/` 对应切片
   - API 问题：检查 `src/server/routers/`
   - 数据库问题：检查 `src/database/schemas/`, `src/database/models/`

3. **分析依赖关系**
   ```bash
   # 检查循环依赖
   pnpm lint:circular
   ```

### 🛠️ 修复策略

#### 类型错误修复

```typescript
// ❌ 错误：隐式 any
let config = {};

// ✅ 正确：明确类型
let config: LobeAgentConfig = DEFAULT_AGENT_CONFIG;

// ❌ 错误：不安全的类型断言
const data = response as any;

// ✅ 正确：使用 Zod 验证
const data = AgentConfigSchema.parse(response);
```

#### 状态管理修复

```typescript
// ❌ 错误：直接修改状态
state.agentMap[id] = newConfig;

// ✅ 正确：使用 immer 不可变更新
return produce(state, (draft) => {
  draft.agentMap[id] = newConfig;
});

// ❌ 错误：选择器直接导出
export const getCurrentAgent = (state) => state.currentAgent;

// ✅ 正确：使用选择器对象模式
export const agentSelectors = {
  getCurrentAgent: (state) => state.currentAgent,
};
```

#### 组件修复

```typescript
// ❌ 错误：缺少 memo 优化
const ExpensiveComponent = ({ data }) => {
  return <div>{/* 复杂渲染 */}</div>;
};

// ✅ 正确：使用 memo 优化
const ExpensiveComponent = memo(({ data }) => {
  return <div>{/* 复杂渲染 */}</div>;
});

// ❌ 错误：不稳定的函数引用
const handleClick = () => doSomething();

// ✅ 正确：使用 useCallback
const handleClick = useCallback(() => doSomething(), []);
```

## 功能开发工作流

### 1. 新功能开发

```bash
# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 分析需求，确定涉及的模块
# - 是否需要新的数据库表？检查 src/database/schemas/
# - 是否需要新的 API？检查 src/server/routers/
# - 是否需要新的状态？检查 src/store/
# - 是否需要新的组件？检查 src/components/, src/features/

# 3. 按依赖顺序开发
# 数据库 -> API -> 状态管理 -> 组件 -> 页面

# 4. 运行测试确保功能正常
pnpm test

# 5. 类型检查
pnpm type-check
```

### 2. Bug 修复流程

```bash
# 1. 重现问题
pnpm dev # 启动开发服务器

# 2. 定位问题
# - 检查浏览器控制台错误
# - 检查网络请求
# - 检查 React DevTools

# 3. 分析根本原因
# - 是数据问题？检查 API 和数据库
# - 是状态问题？检查 Zustand store
# - 是渲染问题？检查组件逻辑

# 4. 编写测试用例（如果没有）
# 5. 修复问题
# 6. 验证修复效果
```

## 数据库操作指南

### Schema 修改

```typescript
// 1. 修改 schema 文件 (src/database/schemas/)
export const newTable = pgTable('new_table', {
  id: text('id').primaryKey(),
  // ... 其他字段
});

// 2. 生成迁移
// pnpm db:generate

// 3. 更新模型类 (src/database/models/)
export class NewModel {
  constructor(
    private db: LobeChatDatabase,
    private userId: string,
  ) {}

  async create(data: NewTableData) {
    return this.db.insert(newTable).values({ ...data, userId: this.userId });
  }
}

// 4. 更新 tRPC 路由 (src/server/routers/)
export const newRouter = router({
  create: protectedProcedure.input(NewTableSchema).mutation(async ({ input, ctx }) => {
    const model = new NewModel(ctx.db, ctx.userId);
    return model.create(input);
  }),
});
```

### 数据迁移

```bash
# 开发环境迁移
pnpm db:migrate

# 生产环境迁移（谨慎操作）
NODE_ENV=production pnpm db:migrate
```

## 性能优化指南

### 1. 组件性能

```typescript
// 使用 React.memo 避免不必要的重渲染
const OptimizedComponent = memo(({ data, onAction }) => {
  // 使用 useMemo 缓存计算结果
  const processedData = useMemo(() =>
    expensiveCalculation(data), [data]
  );

  // 使用 useCallback 稳定函数引用
  const handleAction = useCallback((id) => {
    onAction(id);
  }, [onAction]);

  return <div>{/* 组件内容 */}</div>;
});
```

### 2. 状态管理性能

```typescript
// 使用浅比较选择器
const useAgentData = () => {
  return useAgentStore(
    useCallback(
      (state) => ({
        config: state.currentConfig,
        loading: state.loading,
      }),
      [],
    ),
    shallow, // 重要：使用浅比较
  );
};
```

### 3. 数据库性能

```typescript
// ❌ 避免 N+1 查询
const agents = await db.query.agents.findMany();
for (const agent of agents) {
  const files = await db.query.agentsFiles.findMany({
    where: eq(agentsFiles.agentId, agent.id),
  });
}

// ✅ 使用关联查询
const agentsWithFiles = await db.query.agents.findMany({
  with: {
    files: true,
  },
});
```

## 调试技巧

### 1. 开发工具使用

```typescript
// 使用 Zustand devtools
const useStore = create(
  devtools(
    (set, get) => ({
      // store 实现
    }),
    { name: 'store-name' }, // 便于调试识别
  ),
);

// 使用 React DevTools Profiler
// 在组件中添加 displayName
Component.displayName = 'ComponentName';
```

### 2. 日志记录

```typescript
// ✅ 使用结构化日志
import { logger } from '@/libs/logger';

// ❌ 避免在生产环境记录敏感信息
console.log('API Key:', apiKey);

// ✅ 使用条件日志
if (process.env.NODE_ENV === 'development') {
  console.log('Debug info:', debugData);
}

logger.info('Operation completed', { userId, operation: 'create-agent' });
```

## 测试策略

### 1. 单元测试

```typescript
// 测试选择器
describe('agentSelectors', () => {
  it('should return current agent config', () => {
    const state = { /* mock state */ };
    const config = agentSelectors.currentAgentConfig(state);
    expect(config).toEqual(expectedConfig);
  });
});

// 测试组件
describe('AgentCard', () => {
  it('should render agent information', () => {
    render(<AgentCard agent={mockAgent} />);
    expect(screen.getByText(mockAgent.title)).toBeInTheDocument();
  });
});
```

### 2. 集成测试

```typescript
// 测试完整流程
describe('Agent Creation Flow', () => {
  it('should create agent with knowledge base', async () => {
    // 1. 创建 agent
    const agent = await agentService.create(agentData);

    // 2. 关联知识库
    await agentService.createAgentKnowledgeBase(agent.id, kbId);

    // 3. 验证结果
    const result = await agentService.getFilesAndKnowledgeBases(agent.id);
    expect(result.knowledgeBases).toHaveLength(1);
  });
});
```

## 部署和发布

### 1. 预发布检查

```bash
# 完整的质量检查
pnpm lint       # 代码规范检查
pnpm type-check # 类型检查
pnpm test       # 运行测试
pnpm build      # 构建检查
```

### 2. 数据库迁移

```bash
# 生产环境迁移前的准备
# 1. 备份数据库
# 2. 在测试环境验证迁移
# 3. 准备回滚方案
# 4. 执行迁移
MIGRATION_DB=1 pnpm db:migrate
```

## 紧急问题处理

### 1. 生产环境问题

1. **立即回滚**：如果是部署导致的问题
2. **热修复**：对于关键 bug，创建 hotfix 分支
3. **监控日志**：检查 Sentry 错误报告
4. **用户通知**：及时通知用户已知问题

### 2. 性能问题

1. **识别瓶颈**：使用 React DevTools Profiler
2. **数据库优化**：检查慢查询
3. **缓存策略**：实施适当的缓存
4. **代码分割**：减少初始加载时间

## 🎯 工作原则

记住以下核心原则：

1. **安全第一**：始终优先考虑用户体验和数据安全
2. **渐进式修改**：进行小步骤、可验证的修改
3. **测试驱动**：修改代码前先运行相关测试
4. **文档同步**：代码修改时同步更新相关文档
5. **寻求帮助**：在不确定的情况下寻求团队协助

通过遵循这些指导原则和参考 steering 文档，你可以更有效地维护和改进 Lobe Chat 代码库。