import { ApiClient } from '../core/api-client';

export class AssignmentService {
  constructor(private client: ApiClient) {}

  list(classId: string) {
    return this.client.get(`/classes/${classId}/assignments`, { tags: { name: 'AssignmentList' } });
  }

  studentList() {
    return this.client.get('/student-assignments', { tags: { name: 'StudentAssignmentList' } });
  }

  detail(id: string) {
    return this.client.get(`/assignments/${id}`, { tags: { name: 'AssignmentDetail' } });
  }

  submit(id: string) {
    return this.client.post(`/assignments/${id}/submit`, undefined, { tags: { name: 'AssignmentSubmit' } });
  }

  submitFinal(submissionId: string) {
    return this.client.post(`/assignment-submissions/${submissionId}/submit`, undefined, { tags: { name: 'AssignmentSubmitFinal' } });
  }

  grade(submissionId: string, points: number, feedback?: string) {
    return this.client.post(`/assignment-submissions/${submissionId}/grade`, { points, feedback }, { tags: { name: 'AssignmentGrade' } });
  }

  return_(submissionId: string) {
    return this.client.post(`/assignment-submissions/${submissionId}/return`, undefined, { tags: { name: 'AssignmentReturn' } });
  }

  getSubmissions(id: string) {
    return this.client.get(`/assignments/${id}/submissions`, { tags: { name: 'AssignmentSubmissions' } });
  }

  publish(id: string) {
    return this.client.post(`/assignments/${id}/publish`, undefined, { tags: { name: 'AssignmentPublish' } });
  }
}
