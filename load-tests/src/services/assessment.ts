import { ApiClient, RequestOptions } from '../core/api-client';
import { AnswerPayload } from '../types/api';

export class AssessmentService {
  constructor(private client: ApiClient) {}

  list(classId: string, role: 'Teacher' | 'Student' = 'Teacher') {
    return this.client.get(`/classes/${classId}/assessments`, { tags: { name: `${role}:AssessmentList` } });
  }

  metadata() {
    return this.client.get('/assessments/metadata', { tags: { name: 'Shared:AssessmentMetadata' } });
  }

  detail(id: string, role: 'Teacher' | 'Student' = 'Teacher') {
    return this.client.get(`/assessments/${id}`, { tags: { name: `${role}:AssessmentDetail` } });
  }

  start(id: string) {
    return this.client.post(`/assessments/${id}/start`, undefined, { tags: { name: 'AssessmentStart' } });
  }

  saveAnswers(submissionId: string, payload: AnswerPayload) {
    return this.client.put(`/submissions/${submissionId}/answers`, payload, { tags: { name: 'SaveAnswers' } });
  }

  submit(submissionId: string) {
    return this.client.post(`/submissions/${submissionId}/submit`, undefined, { tags: { name: 'AssessmentSubmit' } });
  }

  getResults(submissionId: string) {
    return this.client.get(`/submissions/${submissionId}/results`, { tags: { name: 'Student:AssessmentResults' } });
  }

  getStatistics(id: string) {
    return this.client.get(`/assessments/${id}/statistics`, { tags: { name: 'Teacher:AssessmentStats' } });
  }

  getSubmissions(id: string, opts?: RequestOptions) {
    return this.client.get(`/assessments/${id}/submissions`, { tags: { name: 'Teacher:AssessmentSubmissions' }, ...opts });
  }

  getSubmissionDetail(id: string) {
    return this.client.get(`/submissions/${id}`, { tags: { name: 'Teacher:SubmissionDetail' } });
  }

  getStudentSubmissions(classId: string, studentId: string, opts?: RequestOptions) {
    return this.client.get(`/classes/${classId}/students/${studentId}/assessment-submissions`, { tags: { name: 'Teacher:StudentAssessmentSubmissions' }, ...opts });
  }

  gradeEssay(answerId: string, points: number, feedback?: string) {
    return this.client.put(`/submission-answers/${answerId}/grade-essay`, { points, feedback }, { tags: { name: 'GradeEssay' } });
  }

  publish(id: string) {
    return this.client.post(`/assessments/${id}/publish`, undefined, { tags: { name: 'AssessmentPublish' } });
  }

  releaseResults(id: string) {
    return this.client.post(`/assessments/${id}/release-results`, undefined, { tags: { name: 'ReleaseResults' } });
  }
}
