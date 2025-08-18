import { ModelProvider } from '@lobechat/model-runtime';

// Use a getter to avoid circular dependencies during module initialization
let _defaultLLMConfig: any = null;

const initLLMConfig = () => {
  if (!_defaultLLMConfig) {
    // Lazy load to avoid circular dependencies
    const { genUserLLMConfig } = require('@/utils/genUserLLMConfig');
    _defaultLLMConfig = genUserLLMConfig({
      lmstudio: {
        fetchOnClient: true,
      },
      ollama: {
        enabled: true,
        fetchOnClient: true,
      },
      openai: {
        enabled: true,
      },
    });
  }
  return _defaultLLMConfig;
};

export const DEFAULT_LLM_CONFIG = new Proxy({} as any, {
  get(_, prop) {
    return initLLMConfig()[prop];
  },
  getOwnPropertyDescriptor(_, prop) {
    return Object.getOwnPropertyDescriptor(initLLMConfig(), prop);
  },
  ownKeys() {
    return Object.keys(initLLMConfig());
  },
});

export const DEFAULT_MODEL = 'gpt-5-mini';

export const DEFAULT_EMBEDDING_MODEL = 'text-embedding-3-small';
export const DEFAULT_EMBEDDING_PROVIDER = ModelProvider.OpenAI;

export const DEFAULT_RERANK_MODEL = 'rerank-english-v3.0';
export const DEFAULT_RERANK_PROVIDER = 'cohere';
export const DEFAULT_RERANK_QUERY_MODE = 'full_text';

export const DEFAULT_PROVIDER = ModelProvider.OpenAI;
