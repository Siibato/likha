import { ApiClient } from '../core/api-client';

export class MaterialService {
  constructor(private client: ApiClient) {}

  list(classId: string) {
    return this.client.get(`/classes/${classId}/materials`, { tags: { name: 'MaterialList' } });
  }

  metadata() {
    return this.client.get('/materials/metadata', { tags: { name: 'MaterialMetadata' } });
  }

  detail(id: string) {
    return this.client.get(`/materials/${id}`, { tags: { name: 'MaterialDetail' } });
  }

  create(classId: string, payload: { title: string; description?: string; content_text?: string }) {
    return this.client.post(`/classes/${classId}/materials`, payload, { tags: { name: 'MaterialCreate' } });
  }

  update(id: string, payload: Record<string, unknown>) {
    return this.client.put(`/materials/${id}`, payload, { tags: { name: 'MaterialUpdate' } });
  }

  downloadFile(fileId: string) {
    return this.client.get(`/material-files/${fileId}/download`, { tags: { name: 'MaterialDownload' }, timeout: '30s' });
  }
}
