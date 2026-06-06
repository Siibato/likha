import { ApiClient } from '../core/api-client';
import { env } from '../config/env';
import http from 'k6/http';

export class AuthService {
  constructor(private client: ApiClient) {}

  me() {
    return this.client.get('/auth/me');
  }

  logout() {
    return this.client.post('/auth/logout');
  }

  refresh(refreshToken: string) {
    return this.client.post('/auth/refresh', { refresh_token: refreshToken });
  }
}

export function loginDirect(username: string, password: string) {
  return http.post(
    `${env.baseUrl}${env.apiPrefix}/auth/login`,
    JSON.stringify({ username, password }),
    { headers: { 'Content-Type': 'application/json' }, timeout: env.setupTimeout },
  );
}
