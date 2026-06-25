import { AnswerPayload, SyncOperation, SyncPushPayload } from '../types/api';

declare const __VU: number;
declare const __ITER: number;

export function fakeAnswers(questionIds: string[]): AnswerPayload {
  const answers: Record<string, string> = {};
  questionIds.forEach((qId, idx) => {
    answers[qId] = `test_answer_vu${__VU}_iter${__ITER}_q${idx}`;
  });
  return { answers };
}

export function fakeSyncPushPayload(
  entityType: string,
  entityId: string,
  data: Record<string, unknown>,
): SyncPushPayload {
  const operation: SyncOperation = {
    entity_type: entityType,
    operation_type: 'create',
    entity_id: entityId,
    data,
    client_timestamp: new Date().toISOString(),
  };
  return { operations: [operation] };
}

export function fakeAssessmentSubmissionPush(
  assessmentId: string,
  studentId: string,
): SyncPushPayload {
  const entityId = `submission_${assessmentId}_${studentId}_${__VU}_${Date.now()}`;
  return fakeSyncPushPayload('assessment_submission', entityId, {
    assessment_id: assessmentId,
    student_id: studentId,
    submitted_at: new Date().toISOString(),
    answers: {},
  });
}

export function fakeAnswerSave(questionIds: string[]): { answers: Record<string, string> } {
  const answers: Record<string, string> = {};
  questionIds.forEach((id, idx) => {
    answers[id] = `option_${(idx % 4) + 1}`;
  });
  return { answers };
}

export function uniqueId(prefix: string): string {
  return `${prefix}_vu${__VU}_${Date.now()}`;
}

export interface ServerPushOperation {
  id: string;
  entity_type: string;
  operation: string;
  payload: Record<string, unknown>;
}

export interface ServerPushPayload {
  operations: ServerPushOperation[];
}

export function fakeGradeScorePush(
  classId: string,
  studentId: string,
  gradeItemId?: string,
): ServerPushPayload {
  const op: ServerPushOperation = {
    id: `op_grade_${__VU}_${__ITER}_${Date.now()}`,
    entity_type: 'grade_score',
    operation: 'update',
    payload: {
      class_id: classId,
      student_id: studentId,
      grade_item_id: gradeItemId ?? `gi_${classId}_default`,
      score: Math.floor(Math.random() * 100),
      grading_period_number: 1,
    },
  };
  return { operations: [op] };
}

export function fakeAssessmentSubmissionServerPush(
  assessmentId: string,
  studentId: string,
): ServerPushPayload {
  const op: ServerPushOperation = {
    id: `op_sub_${__VU}_${__ITER}_${Date.now()}`,
    entity_type: 'assessment_submission',
    operation: 'create',
    payload: {
      assessment_id: assessmentId,
      student_id: studentId,
      submitted_at: new Date().toISOString(),
      answers: {},
    },
  };
  return { operations: [op] };
}

export function fakeAssignmentSubmissionServerPush(
  assignmentId: string,
  studentId: string,
): ServerPushPayload {
  const op: ServerPushOperation = {
    id: `op_asub_${__VU}_${__ITER}_${Date.now()}`,
    entity_type: 'assignment_submission',
    operation: 'create',
    payload: {
      assignment_id: assignmentId,
      student_id: studentId,
      submitted_at: new Date().toISOString(),
    },
  };
  return { operations: [op] };
}
