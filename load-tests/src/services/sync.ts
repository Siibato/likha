import { ApiClient } from '../core/api-client';
import { SyncPushPayload, SyncDeltaPayload, FullSyncPayload } from '../types/api';

export class SyncService {
  constructor(private client: ApiClient) {}

  fullSync(deviceId: string, classIds?: string[]) {
    const payload: FullSyncPayload = { device_id: deviceId };
    if (classIds !== undefined) {
      payload.class_ids = classIds;
    }
    return this.client.post('/sync/full', payload, {
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
