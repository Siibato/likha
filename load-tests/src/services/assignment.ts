import { ApiClient, RequestOptions } from '../core/api-client';

export class AssignmentService {
  constructor(private client: ApiClient) {}

  list(classId: string, role: 'Teacher' | 'Student' = 'Teacher') {
    return this.client.get(`/classes/${classId}/assignments`, { tags: { name: `${role}:AssignmentList` } });
  }

  metadata(classId: string) {
    return this.client.get(`/classes/${classId}/assignments/metadata`, { tags: { name: 'Shared:AssignmentMetadata' } });
  }

  studentList() {
    return this.client.get('/student-assignments', { tags: { name: 'Student:AssignmentList' } });
  }

  detail(id: string, role: 'Teacher' | 'Student' = 'Teacher') {
    return this.client.get(`/assignments/${id}`, { tags: { name: `${role}:AssignmentDetail` } });
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

  getSubmissions(id: string, opts?: RequestOptions) {
    return this.client.get(`/assignments/${id}/submissions`, { tags: { name: 'Teacher:AssignmentSubmissions' }, ...opts });
  }

  getSubmissionDetail(id: string) {
    return this.client.get(`/assignment-submissions/${id}`, { tags: { name: 'Teacher:AssignmentSubmissionDetail' } });
  }

  getStudentSubmissions(assignmentId: string, studentId: string) {
    return this.client.get(`/assignments/${assignmentId}/students/${studentId}/submissions`, { tags: { name: 'Teacher:StudentAssignmentSubmissions' } });
  }

  downloadFile(fileId: string) {
    return this.client.get(`/submission-files/${fileId}/download`, { tags: { name: 'Shared:SubmissionDownload' }, timeout: '30s' });
  }

  publish(id: string) {
    return this.client.post(`/assignments/${id}/publish`, undefined, { tags: { name: 'AssignmentPublish' } });
  }
}
