export interface LoginResponse {
  token: string;
  access_token?: string;
}

export interface User {
  id: string;
  username: string;
  full_name: string;
  role: 'admin' | 'teacher' | 'student';
  account_status: string;
}

export interface Class {
  id: string;
  title: string;
  description?: string;
  grade_level?: string;
  school_year?: string;
  is_advisory: boolean;
  is_archived: boolean;
  created_at: string;
}

export interface Assessment {
  id: string;
  class_id: string;
  title: string;
  total_points: number;
  is_published: boolean;
  results_released: boolean;
  grading_period_number: number;
  open_at: string;
  close_at: string;
}

export interface Question {
  id: string;
  question_type: string;
  text: string;
  points: number;
  order: number;
  choices?: Choice[];
}

export interface Choice {
  id: string;
  text: string;
  order: number;
}

export interface AssessmentSubmission {
  id: string;
  assessment_id: string;
  student_id: string;
  status: string;
  started_at: string;
  submitted_at?: string;
}

export interface AnswerPayload {
  answers: Record<string, string | string[]>;
}

export interface Assignment {
  id: string;
  class_id: string;
  title: string;
  total_points: number;
  is_published: boolean;
  due_at: string;
  grading_period_number: number;
}

export interface SyncOperation {
  entity_type: string;
  operation_type: 'create' | 'update' | 'delete';
  entity_id: string;
  data: Record<string, unknown>;
  client_timestamp: string;
}

export interface SyncPushPayload {
  operations: SyncOperation[];
  device_id?: string;
}

export interface SyncDeltaPayload {
  device_id: string;
  last_sync_at: string;
}

export interface FullSyncPayload {
  device_id: string;
  class_ids?: string[];
}

export interface GradeItem {
  id: string;
  class_id: string;
  title: string;
  max_score: number;
  component: string;
  grading_period_number: number;
}
