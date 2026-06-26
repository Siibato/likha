import { sleep } from 'k6';
import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { SyncService } from '../services/sync';
import { expectAll, expectNoServerError } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { studentAccounts } from '../data/accounts';
import { fakeAssessmentSubmissionPush } from '../data/fixtures';
import { publishedAssessments, manifest, randomItem, activeClasses } from '../data/manifest';
import { TokenMap } from '../types/scenario';

// Tests POST /sync/deltas vs POST /sync/full under load to compare bandwidth/latency.
// 60% delta sync, 30% full sync, 10% sync push.
const VU_COUNT = 100;

export const options: Options = buildOptions(stages.gradualRamp(VU_COUNT), thresholds.sync);

export const handleSummary = createReportGenerator('delta-sync').handleSummary;

export function setup(): TokenMap {
  console.log('Delta sync setup: logging in students...');
  const tokens = loginAll(studentAccounts, VU_COUNT);
  console.log(`Setup complete: ${Object.keys(tokens).length} students ready`);
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
  const syncService = new SyncService(client);
  const rand = Math.random();

  if (rand < 0.6) {
    // Delta sync: simulate a device that last synced some time ago (varies 1min to 24h)
    const minutesAgo = Math.floor(Math.random() * 1440) + 1;
    const lastSyncAt = new Date(Date.now() - minutesAgo * 60 * 1000).toISOString();
    const res = syncService.deltaSync({ device_id: `vu_${__VU}`, last_sync_at: lastSyncAt });
    expectAll(res, 'delta-sync', { status: 200, underMs: 800 });
    expectNoServerError(res, 'delta-sync');
  } else if (rand < 0.9) {
    // Full sync (batch request with class_ids for heavy data)
    const classIds = activeClasses.map(c => c.id);
    const res = syncService.fullSync(`vu_${__VU}`, classIds);
    expectAll(res, 'full-sync', { status: 200, underMs: 3000 });
    expectNoServerError(res, 'full-sync');
  } else {
    // Sync push
    if (publishedAssessments.length > 0) {
      const assessment = randomItem(publishedAssessments);
      const student = randomItem(manifest.users.filter(u => u.role === 'student'));
      const payload = fakeAssessmentSubmissionPush(assessment.id, student.id);
      const res = syncService.push(payload);
      expectAll(res, 'sync-push', { status: 200, underMs: 1000 });
      expectNoServerError(res, 'sync-push');
    }
  }

  sleep(1);
}
