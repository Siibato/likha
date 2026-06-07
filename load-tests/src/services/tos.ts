import { ApiClient, RequestOptions } from '../core/api-client';

export class TosService {
  constructor(private client: ApiClient) {}

  list(classId: string, opts?: RequestOptions) {
    return this.client.get(`/classes/${classId}/tos`, { tags: { name: 'Teacher:TosList' }, ...opts });
  }

  detail(id: string) {
    return this.client.get(`/tos/${id}`, { tags: { name: 'Teacher:TosDetail' } });
  }

  create(classId: string, payload: Record<string, unknown>) {
    return this.client.post(`/classes/${classId}/tos`, payload, { tags: { name: 'TosCreate' } });
  }

  addCompetency(tosId: string, payload: Record<string, unknown>) {
    return this.client.post(`/tos/${tosId}/competencies`, payload, { tags: { name: 'TosAddCompetency' } });
  }

  searchMelcs(query: string, opts?: RequestOptions) {
    return this.client.get(`/melcs?q=${encodeURIComponent(query)}`, { tags: { name: 'Teacher:MelcsSearch' }, ...opts });
  }
}
