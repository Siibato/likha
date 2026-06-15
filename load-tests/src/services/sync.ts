import { ApiClient } from '../core/api-client';
import { SyncPushPayload, SyncDeltaPayload } from '../types/api';

export class SyncService {
  constructor(private client: ApiClient) {}

  fullSync() {
    return this.client.post('/sync/full', undefined, {
      tags: { name: 'Sync:Full' },
      timeout: '15s',
    });
  }

  deltaSync(payload: SyncDeltaPayload) {
    return this.client.post('/sync/deltas', payload, {
      tags: { name: 'Sync:Delta' },
      timeout: '10s',
    });
  }

  push(payload: SyncPushPayload) {
    return this.client.post('/sync/push', payload, {
      tags: { name: 'SyncPush' },
      timeout: '10s',
    });
  }

  resolveConflict(payload: Record<string, unknown>) {
    return this.client.post('/sync/conflicts/resolve', payload, {
      tags: { name: 'SyncConflict' },
    });
  }
}
