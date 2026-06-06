import { ApiClient } from '../core/api-client';

export class HealthService {
  constructor(private client: ApiClient) {}

  health() {
    return this.client.get('/health', { tags: { name: 'Health:Check' } });
  }

  ready() {
    return this.client.get('/health/ready', { tags: { name: 'Health:Ready' } });
  }

  databaseId() {
    return this.client.get('/database-id', { tags: { name: 'Health:DatabaseId' } });
  }
}
