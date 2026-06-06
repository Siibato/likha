import { sleep } from 'k6';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginPool } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { ClassService } from '../services/class';
import { AssessmentService } from '../services/assessment';
import { AssignmentService } from '../services/assignment';
import { expectAll } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { teacherAccounts } from '../data/accounts';
import { TokenMap } from '../types/scenario';

export const options: Options = buildOptions(stages.baseline, thresholds.strict);

export function setup(): TokenMap {
  console.log('Baseline setup: logging in teachers...');
  const tokens = loginPool(teacherAccounts);
  console.log(`Setup complete: ${Object.keys(tokens).length} teachers ready`);
  return tokens;
}

declare const __VU: number;

export default function (tokens: TokenMap): void {
  const token = tokens[__VU];
  if (!token) {
    console.error(`No token for VU ${__VU}`);
    return;
  }

  const client = new ApiClient(token);
  const classService = new ClassService(client);
  const assessmentService = new AssessmentService(client);
  const assignmentService = new AssignmentService(client);

  const classRes = classService.list();
  expectAll(classRes, 'baseline-classes', { status: 200, underMs: 200 });
  sleep(0.5);

  const assessRes = assessmentService.metadata();
  expectAll(assessRes, 'baseline-assessments', { status: 200, underMs: 200 });
  sleep(0.5);

  const assignRes = assignmentService.studentList();
  expectAll(assignRes, 'baseline-assignments', { status: 200, underMs: 200 });
  sleep(1);
}
