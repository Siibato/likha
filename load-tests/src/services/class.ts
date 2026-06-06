import { ApiClient } from '../core/api-client';

export class ClassService {
  constructor(private client: ApiClient) {}

  list() {
    return this.client.get('/classes', { tags: { name: 'ClassList' } });
  }

  detail(id: string) {
    return this.client.get(`/classes/${id}`, { tags: { name: 'ClassDetail' } });
  }

  metadata() {
    return this.client.get('/classes/metadata', { tags: { name: 'ClassMetadata' } });
  }

  create(payload: { title: string; description?: string; grade_level?: string; school_year?: string }) {
    return this.client.post('/classes', payload, { tags: { name: 'ClassCreate' } });
  }

  update(id: string, payload: Record<string, unknown>) {
    return this.client.put(`/classes/${id}`, payload, { tags: { name: 'ClassUpdate' } });
  }

  addStudent(classId: string, studentId: string) {
    return this.client.post(`/classes/${classId}/students`, { student_id: studentId }, { tags: { name: 'ClassEnroll' } });
  }

  removeStudent(classId: string, studentId: string) {
    return this.client.delete(`/classes/${classId}/students/${studentId}`, { tags: { name: 'ClassUnenroll' } });
  }
}
