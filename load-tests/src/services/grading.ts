import { ApiClient } from '../core/api-client';

export class GradingService {
  constructor(private client: ApiClient) {}

  getConfig(classId: string) {
    return this.client.get(`/classes/${classId}/grading-config`, { tags: { name: 'GradingConfig' } });
  }

  getGradeItems(classId: string) {
    return this.client.get(`/classes/${classId}/grade-items`, { tags: { name: 'GradeItems' } });
  }

  updateScores(gradeItemId: string, scores: Record<string, number>) {
    return this.client.put(`/grade-items/${gradeItemId}/scores`, { scores }, { tags: { name: 'UpdateScores' } });
  }

  updateScoresBatch(payload: { scores: Array<{ grade_score_id: string; score: number }> }) {
    return this.client.put('/grade-scores/batch', payload, { tags: { name: 'BatchScores' } });
  }

  compute(classId: string) {
    return this.client.post(`/classes/${classId}/grades/compute`, undefined, {
      tags: { name: 'ComputeGrades' },
      timeout: '15s',
    });
  }

  getGrades(classId: string) {
    return this.client.get(`/classes/${classId}/grades`, { tags: { name: 'GetGrades' } });
  }

  getGradeSummary(classId: string) {
    return this.client.get(`/classes/${classId}/grades/summary`, { tags: { name: 'GradeSummary' } });
  }

  getMyGrades(classId: string) {
    return this.client.get(`/classes/${classId}/my-grades`, { tags: { name: 'MyGrades' } });
  }

  getSf9(classId: string, studentId: string) {
    return this.client.get(`/classes/${classId}/sf9/${studentId}`, { tags: { name: 'SF9' } });
  }

  getSf10(classId: string, studentId: string) {
    return this.client.get(`/classes/${classId}/sf10/${studentId}`, { tags: { name: 'SF10' } });
  }
}
