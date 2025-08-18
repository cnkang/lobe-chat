
// Use a getter function to avoid circular dependencies during module initialization
export const getDefaultAgentConfig = () => {
  // Import types and other dependencies only when needed
  const { DEFAULT_AGENT_META } = require('../meta');
  const { DEFAULT_MODEL, DEFAULT_PROVIDER } = require('./llm');

  const DEFAUTT_AGENT_TTS_CONFIG = {
    showAllLocaleVoice: false,
    sttLocale: 'auto',
    ttsService: 'openai',
    voice: {
      openai: 'alloy',
    },
  };

  const DEFAULT_AGENT_SEARCH_FC_MODEL = {
    model: DEFAULT_MODEL,
    provider: DEFAULT_PROVIDER,
  };

  const DEFAULT_AGENT_CHAT_CONFIG = {
    autoCreateTopicThreshold: 2,
    displayMode: 'chat',
    enableAutoCreateTopic: true,
    enableCompressHistory: true,
    enableHistoryCount: true,
    enableReasoning: false,
    historyCount: 20,
    reasoningBudgetToken: 1024,
    searchFCModel: DEFAULT_AGENT_SEARCH_FC_MODEL,
    searchMode: 'off',
  };

  const DEFAULT_AGENT_CONFIG = {
    chatConfig: DEFAULT_AGENT_CHAT_CONFIG,
    model: DEFAULT_MODEL,
    openingQuestions: [],
    params: {
      frequency_penalty: 0,
      presence_penalty: 0,
      temperature: 1,
      top_p: 1,
    },
    plugins: [],
    provider: DEFAULT_PROVIDER,
    systemRole: '',
    tts: DEFAUTT_AGENT_TTS_CONFIG,
  };

  const DEFAULT_AGENT = {
    config: DEFAULT_AGENT_CONFIG,
    meta: DEFAULT_AGENT_META,
  };

  return {
    DEFAULT_AGENT,
    DEFAULT_AGENT_CHAT_CONFIG,
    DEFAULT_AGENT_CONFIG,
    DEFAULT_AGENT_SEARCH_FC_MODEL,
    DEFAUTT_AGENT_TTS_CONFIG,
  };
};

// Export individual constants using getters to avoid circular dependencies
export const DEFAUTT_AGENT_TTS_CONFIG = new Proxy({} as any, {
  get() {
    return getDefaultAgentConfig().DEFAUTT_AGENT_TTS_CONFIG;
  },
});

export const DEFAULT_AGENT_SEARCH_FC_MODEL = new Proxy({} as any, {
  get() {
    return getDefaultAgentConfig().DEFAULT_AGENT_SEARCH_FC_MODEL;
  },
});

export const DEFAULT_AGENT_CHAT_CONFIG = new Proxy({} as any, {
  get() {
    return getDefaultAgentConfig().DEFAULT_AGENT_CHAT_CONFIG;
  },
});

export const DEFAULT_AGENT_CONFIG = new Proxy({} as any, {
  get() {
    return getDefaultAgentConfig().DEFAULT_AGENT_CONFIG;
  },
});

export const DEFAULT_AGENT = new Proxy({} as any, {
  get() {
    return getDefaultAgentConfig().DEFAULT_AGENT;
  },
});
