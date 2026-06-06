declare const __ENV: Record<string, string>;

export const env = {
  baseUrl: __ENV.BASE_URL || 'http://localhost:8000',
  apiPrefix: '/api/v1',
  defaultTimeout: '10s',
  setupTimeout: '5s',
} as const;

export type Env = typeof env;
