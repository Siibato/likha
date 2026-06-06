import http, { RefinedResponse, ResponseType } from 'k6/http';
import { env } from '../config/env';

export type RequestOptions = {
  timeout?: string;
  tags?: Record<string, string>;
};

export class ApiClient {
  private readonly baseUrl: string;
  private readonly authHeader: Record<string, string>;

  constructor(token: string) {
    this.baseUrl = `${env.baseUrl}${env.apiPrefix}`;
    this.authHeader = {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
  }

  get(path: string, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    return http.get(`${this.baseUrl}${path}`, {
      headers: this.authHeader,
      timeout: opts.timeout ?? env.defaultTimeout,
      tags: opts.tags,
    });
  }

  post(path: string, body?: unknown, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    return http.post(
      `${this.baseUrl}${path}`,
      body !== undefined ? JSON.stringify(body) : null,
      {
        headers: this.authHeader,
        timeout: opts.timeout ?? env.defaultTimeout,
        tags: opts.tags,
      },
    );
  }

  put(path: string, body?: unknown, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    return http.put(
      `${this.baseUrl}${path}`,
      body !== undefined ? JSON.stringify(body) : null,
      {
        headers: this.authHeader,
        timeout: opts.timeout ?? env.defaultTimeout,
        tags: opts.tags,
      },
    );
  }

  delete(path: string, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    return http.del(`${this.baseUrl}${path}`, null, {
      headers: this.authHeader,
      timeout: opts.timeout ?? env.defaultTimeout,
      tags: opts.tags,
    });
  }
}
