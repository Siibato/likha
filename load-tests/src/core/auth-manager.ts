import http from 'k6/http';
import { check } from 'k6';
import { env } from '../config/env';
import { Account, TokenMap } from '../types/scenario';

export function loginOne(account: Account): string {
  const res = http.post(
    `${env.baseUrl}${env.apiPrefix}/auth/login`,
    JSON.stringify({ username: account.username, password: account.password }),
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: env.setupTimeout,
    },
  );

  const ok = check(res, {
    'login: status 200': (r) => r.status === 200,
  });

  if (!ok) {
    throw new Error(
      `Login failed for ${account.username}: HTTP ${res.status} — ${res.body}`,
    );
  }

  let token = '';
  try {
    const body = res.json() as Record<string, unknown>;
    token = (body.token ?? body.access_token ?? '') as string;
  } catch {
    throw new Error(`Login response parse failed for ${account.username}`);
  }

  if (!token) {
    throw new Error(`No token returned for ${account.username}`);
  }

  return token;
}

export function loginAll(pool: Account[], count: number): TokenMap {
  const tokens: TokenMap = {};
  for (let i = 1; i <= count; i++) {
    const account = pool[(i - 1) % pool.length];
    tokens[i] = loginOne(account);
  }
  return tokens;
}

export function loginPool(pool: Account[]): TokenMap {
  return loginAll(pool, pool.length);
}
