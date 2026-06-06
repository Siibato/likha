import { ApiClient } from '../core/api-client';
import { AnswerPayload } from '../types/api';

export class AssessmentService {
  constructor(private client: ApiClient) {}

  list(classId: string) {
    return this.client.get(`/classes/${classId}/assessments`, { tags: { name: 'AssessmentList' } });
  }

  metadata() {
    return this.client.get('/assessments/metadata', { tags: { name: 'AssessmentMetadata' } });
  }

  detail(id: string) {
    return this.client.get(`/assessments/${id}`, { tags: { name: 'AssessmentDetail' } });
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
    return this.client.get(`/submissions/${submissionId}/results`, { tags: { name: 'AssessmentResults' } });
  }

  getStatistics(id: string) {
    return this.client.get(`/assessments/${id}/statistics`, { tags: { name: 'AssessmentStats' } });
  }

  getSubmissions(id: string) {
    return this.client.get(`/assessments/${id}/submissions`, { tags: { name: 'AssessmentSubmissions' } });
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
