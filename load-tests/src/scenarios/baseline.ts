import { sleep } from 'k6';
import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { ClassService } from '../services/class';
import { AssessmentService } from '../services/assessment';
import { AssignmentService } from '../services/assignment';
import { expectAll } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { teacherAccounts, studentAccounts } from '../data/accounts';
import { activeClasses } from '../data/manifest';
import { MixedSetupData } from '../types/scenario';

const endpointThresholds = {
  'http_req_duration{name:ClassList}': ['p(95)<99000'],
  'http_req_duration{name:AssessmentMetadata}': ['p(95)<99000'],
  'http_req_duration{name:AssignmentList}': ['p(95)<99000'],
  'http_req_duration{name:StudentAssignmentList}': ['p(95)<99000'],
};

export const options: Options = buildOptions(stages.baseline, thresholds.normal, endpointThresholds);

export const handleSummary = createReportGenerator('baseline').handleSummary;

const TEACHER_VUS = 10;
const STUDENT_VUS = 20;

export function setup(): MixedSetupData {
  console.log(`Baseline setup: logging in ${TEACHER_VUS} teachers + ${STUDENT_VUS} students...`);
  const teacherTokens = loginAll(teacherAccounts, TEACHER_VUS);
  const studentTokens = loginAll(studentAccounts, STUDENT_VUS);
  console.log(`Setup complete: ${Object.keys(teacherTokens).length} teachers + ${Object.keys(studentTokens).length} students ready`);
  return { teacherTokens, studentTokens };
}

declare const __VU: number;

export default function (data: MixedSetupData): void {
  const isTeacher = __VU <= TEACHER_VUS;

  if (isTeacher) {
    const token = data.teacherTokens[__VU];
    if (!token) {
      console.error(`No teacher token for VU ${__VU}`);
      return;
    }
    runTeacherFlow(token);
  } else {
    const studentVuIndex = __VU - TEACHER_VUS;
    const token = data.studentTokens[studentVuIndex];
    if (!token) {
      console.error(`No student token for VU ${__VU} (index ${studentVuIndex})`);
      return;
    }
    runStudentFlow(token);
  }
}

function runTeacherFlow(token: string): void {
  const client = new ApiClient(token);
  const classService = new ClassService(client);
  const assessmentService = new AssessmentService(client);
  const assignmentService = new AssignmentService(client);

  const classRes = classService.list();
  expectAll(classRes, 'baseline-teacher-classes', { status: 200, underMs: 500 });
  sleep(0.5);

  const assessRes = assessmentService.metadata();
  expectAll(assessRes, 'baseline-teacher-assessments', { status: 200, underMs: 500 });
  sleep(0.5);

  const classId = activeClasses[(__VU - 1) % activeClasses.length].id;
  const assignRes = assignmentService.list(classId);
  expectAll(assignRes, 'baseline-teacher-assignments', { status: 200, underMs: 500 });
  sleep(1);
}

function runStudentFlow(token: string): void {
  const client = new ApiClient(token);
  const classService = new ClassService(client);
  const assessmentService = new AssessmentService(client);
  const assignmentService = new AssignmentService(client);

  const classRes = classService.list();
  expectAll(classRes, 'baseline-student-classes', { status: 200, underMs: 500 });
  sleep(0.5);

  const assessRes = assessmentService.metadata();
  expectAll(assessRes, 'baseline-student-assessments', { status: 200, underMs: 500 });
  sleep(0.5);

  const assignRes = assignmentService.studentList();
  expectAll(assignRes, 'baseline-student-assignments', { status: 200, underMs: 500 });
  sleep(1);
}
