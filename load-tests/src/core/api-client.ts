import http, { RefinedResponse, ResponseType } from 'k6/http';
import { env } from '../config/env';

export type RequestOptions = {
  timeout?: string;
  tags?: Record<string, string>;
  expectedStatuses?: number[];
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
    const params: any = {
      headers: this.authHeader,
      timeout: opts.timeout ?? env.defaultTimeout,
      tags: opts.tags,
    };
    if (opts.expectedStatuses) {
      params.responseCallback = http.expectedStatuses(...opts.expectedStatuses);
    }
    return http.get(`${this.baseUrl}${path}`, params);
  }

  post(path: string, body?: unknown, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    const params: any = {
      headers: this.authHeader,
      timeout: opts.timeout ?? env.defaultTimeout,
      tags: opts.tags,
    };
    if (opts.expectedStatuses) {
      params.responseCallback = http.expectedStatuses(...opts.expectedStatuses);
    }
    return http.post(
      `${this.baseUrl}${path}`,
      body !== undefined ? JSON.stringify(body) : null,
      params,
    );
  }

  put(path: string, body?: unknown, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    const params: any = {
      headers: this.authHeader,
      timeout: opts.timeout ?? env.defaultTimeout,
      tags: opts.tags,
    };
    if (opts.expectedStatuses) {
      params.responseCallback = http.expectedStatuses(...opts.expectedStatuses);
    }
    return http.put(
      `${this.baseUrl}${path}`,
      body !== undefined ? JSON.stringify(body) : null,
      params,
    );
  }

  delete(path: string, opts: RequestOptions = {}): RefinedResponse<ResponseType> {
    const params: any = {
      headers: this.authHeader,
      timeout: opts.timeout ?? env.defaultTimeout,
      tags: opts.tags,
    };
    if (opts.expectedStatuses) {
      params.responseCallback = http.expectedStatuses(...opts.expectedStatuses);
    }
    return http.del(`${this.baseUrl}${path}`, null, params);
  }
}
