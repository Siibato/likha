import { sleep } from 'k6';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { ClassService } from '../services/class';
import { AssessmentService } from '../services/assessment';
import { SyncService } from '../services/sync';
import { expectAll, expectNoServerError } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { studentAccounts } from '../data/accounts';
import { TokenMap } from '../types/scenario';

const VU_COUNT = 500;

export const options: Options = buildOptions(stages.stress, thresholds.stress);

export function setup(): TokenMap {
  console.log('Stress setup: logging in students...');
  const tokens = loginAll(studentAccounts, VU_COUNT);
  console.log(`Setup complete: ${Object.keys(tokens).length} users ready`);
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
  const rand = Math.random();

  if (rand < 0.4) {
    const syncService = new SyncService(client);
    const res = syncService.fullSync();
    expectAll(res, 'stress-sync-full', { status: 200, underMs: 1000 });
    expectNoServerError(res, 'stress-sync-full');
  } else if (rand < 0.7) {
    const classService = new ClassService(client);
    const res = classService.list();
    expectAll(res, 'stress-classes', { status: 200, underMs: 500 });
  } else {
    const assessmentService = new AssessmentService(client);
    const res = assessmentService.metadata();
    expectAll(res, 'stress-assessments', { status: 200, underMs: 500 });
  }

  sleep(1);
}
