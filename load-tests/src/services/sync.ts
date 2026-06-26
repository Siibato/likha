import { ApiClient, RequestOptions } from '../core/api-client';
import { SyncPushPayload, SyncDeltaPayload, FullSyncPayload } from '../types/api';

export class SyncService {
  constructor(private client: ApiClient) {}

  fullSync(deviceId: string, classIds?: string[], opts?: RequestOptions) {
    const payload: FullSyncPayload = { device_id: deviceId };
    if (classIds !== undefined) {
      payload.class_ids = classIds;
    }
    return this.client.post('/sync/full', payload, {
      tags: { name: 'Sync:Full' },
      timeout: '15s',
      ...opts,
    });
  }

  deltaSync(payload: SyncDeltaPayload, opts?: RequestOptions) {
    return this.client.post('/sync/deltas', payload, {
      tags: { name: 'Sync:Delta' },
      timeout: '10s',
      ...opts,
    });
  }

  push(payload: SyncPushPayload, opts?: RequestOptions) {
    return this.client.post('/sync/push', payload, {
      tags: { name: 'SyncPush' },
      timeout: '10s',
      ...opts,
    });
  }

  resolveConflict(payload: Record<string, unknown>, opts?: RequestOptions) {
    return this.client.post('/sync/conflicts/resolve', payload, {
      tags: { name: 'SyncConflict' },
      ...opts,
    });
  }
}
