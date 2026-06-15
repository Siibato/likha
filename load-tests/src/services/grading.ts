import { ApiClient, RequestOptions } from '../core/api-client';

export class GradingService {
  constructor(private client: ApiClient) {}

  getConfig(classId: string) {
    return this.client.get(`/classes/${classId}/grading-config`, { tags: { name: 'Teacher:GradingConfig' } });
  }

  getGradeItems(classId: string) {
    return this.client.get(`/classes/${classId}/grade-items`, { tags: { name: 'Teacher:GradeItems' } });
  }

  getItemScores(itemId: string) {
    return this.client.get(`/grade-items/${itemId}/scores`, { tags: { name: 'Teacher:ItemScores' } });
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
    return this.client.get(`/classes/${classId}/grades`, { tags: { name: 'Teacher:Grades' } });
  }

  getFinalGrades(classId: string) {
    return this.client.get(`/classes/${classId}/grades/final`, { tags: { name: 'Teacher:FinalGrades' } });
  }

  getGradeSummary(classId: string) {
    return this.client.get(`/classes/${classId}/grades/summary`, { tags: { name: 'Teacher:GradeSummary' } });
  }

  getGradeData(classId: string) {
    return this.client.get(`/classes/${classId}/grade-data`, { tags: { name: 'Teacher:AllGradeData' }, timeout: '10s' });
  }

  getMyGrades(classId: string) {
    return this.client.get(`/classes/${classId}/my-grades`, { tags: { name: 'Student:MyGrades' } });
  }

  getMyQuarterGrades(classId: string, quarter: string) {
    return this.client.get(`/classes/${classId}/my-grades/${quarter}`, { tags: { name: 'Student:MyQuarterGrades' } });
  }

  getGeneralAverages(classId: string, opts?: RequestOptions) {
    return this.client.get(`/classes/${classId}/grades/general-average`, { tags: { name: 'Teacher:GeneralAverages' }, ...opts });
  }

  getDepedPresets() {
    return this.client.get('/grading/deped-presets', { tags: { name: 'Teacher:DepedPresets' } });
  }

  getSf9(classId: string, studentId: string) {
    return this.client.get(`/classes/${classId}/sf9/${studentId}`, { tags: { name: 'Teacher:SF9' } });
  }

  getSf10(classId: string, studentId: string) {
    return this.client.get(`/classes/${classId}/sf10/${studentId}`, { tags: { name: 'Teacher:SF10' } });
  }
}
