import { ApiClient } from '../core/api-client';

export class TosService {
  constructor(private client: ApiClient) {}

  list(classId: string) {
    return this.client.get(`/classes/${classId}/tos`, { tags: { name: 'TosList' } });
  }

  detail(id: string) {
    return this.client.get(`/tos/${id}`, { tags: { name: 'TosDetail' } });
  }

  create(classId: string, payload: Record<string, unknown>) {
    return this.client.post(`/classes/${classId}/tos`, payload, { tags: { name: 'TosCreate' } });
  }

  addCompetency(tosId: string, payload: Record<string, unknown>) {
    return this.client.post(`/tos/${tosId}/competencies`, payload, { tags: { name: 'TosAddCompetency' } });
  }

  searchMelcs(query: string) {
    return this.client.get(`/melcs?q=${encodeURIComponent(query)}`, { tags: { name: 'MelcsSearch' } });
  }
}
