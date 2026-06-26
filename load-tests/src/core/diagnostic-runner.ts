import { RefinedResponse, ResponseType } from 'k6/http';
import { ApiClient } from './api-client';
import { HealthService } from '../services/health';
import { AuthService } from '../services/auth';
import { ClassService } from '../services/class';
import { AssessmentService } from '../services/assessment';
import { AssignmentService } from '../services/assignment';
import { GradingService } from '../services/grading';
import { MaterialService } from '../services/material';
import { TosService } from '../services/tos';
import { SyncService } from '../services/sync';
import { AdminService } from '../services/admin';
import {
  activeClasses,
  publishedAssessments,
  publishedAssignments,
  students,
  manifest,
} from '../data/manifest';
import {
  fakeGradeScorePush,
  fakeAssessmentSubmissionServerPush,
} from '../data/fixtures';

export interface ProbeResult {
  endpoint: string;
  ok: boolean;
  status: number;
  latency: number;
  body?: string;
  error?: string;
}

export const DIAGNOSTIC_ENDPOINT_NAMES = [
  'Health:Check',
  'Health:Ready',
  'Health:DatabaseId',
  'Auth:Me',
  'Shared:ClassMetadata',
  'Shared:AssessmentMetadata',
  'Shared:MaterialMetadata',
  'Teacher:ClassList',
  'Teacher:ClassDetail',
  'Teacher:AssessmentList',
  'Teacher:AssessmentDetail',
  'Teacher:AssessmentStats',
  'Teacher:AssessmentSubmissions',
  'Teacher:AssignmentList',
  'Teacher:AssignmentDetail',
  'Teacher:AssignmentSubmissions',
  'Teacher:GradingConfig',
  'Teacher:GradeItems',
  'Teacher:Grades',
  'Teacher:GradeSummary',
  'Teacher:FinalGrades',
  'Teacher:GeneralAverages',
  'Teacher:DepedPresets',
  'Teacher:ItemScores',
  'Teacher:TosList',
  'Teacher:TosDetail',
  'Teacher:MelcsSearch',
  'Teacher:MaterialList',
  'Teacher:MaterialDetail',
  'Teacher:AllGradeData',
  'Teacher:SF9',
  'Teacher:SF10',
  'SyncPush:TeacherGrade',
  'Student:ClassList',
  'Student:ClassDetail',
  'Student:AssignmentList',
  'Student:AssignmentDetail',
  'Student:MyGrades',
  'Student:MyTermGrades',
  'Student:MaterialList',
  'Student:MaterialDetail',
  'Student:AssessmentList',
  'Student:AssessmentDetail',
  'SyncPush:StudentSubmission',
  'Admin:AccountList',
  'Admin:AccountDetail',
  'Admin:ActivityLogs',
  'Admin:SetupQr',
  'Admin:SetupCode',
  'Admin:SchoolSettings',
  'Admin:StudentSearch',
  'Sync:Delta',
  'Sync:Full',
] as const;

export function runDiagnosticProbe(
  tokens: { teacher: string; student: string; admin: string },
  mode?: { noThrow?: boolean; namePrefix?: string },
): ProbeResult[] {
  const noThrow = mode?.noThrow ?? false;
  const namePrefix = mode?.namePrefix;
  const results: ProbeResult[] = [];

  function call(name: string, fn: () => RefinedResponse<ResponseType>, opts?: { skipThrow?: boolean }): RefinedResponse<ResponseType> {
    console.log(`→ ${name}`);
    const res = fn();
    const ok = res.status >= 200 && res.status < 300 && !res.error;
    const bodyPreview = typeof res.body === 'string' ? res.body.substring(0, 300) : '';
    if (!ok) {
      console.log(`  FAIL status=${res.status} error=${res.error || ''} body=${bodyPreview}`);
      results.push({ endpoint: name, ok: false, status: res.status, latency: res.timings.duration, body: bodyPreview, error: res.error || '' });
      if (!opts?.skipThrow && !noThrow) {
        throw new Error(`${name} failed: HTTP ${res.status}${res.error ? ' — ' + res.error : ''}`);
      }
    } else {
      console.log(`  OK ${res.status} (${res.timings.duration.toFixed(1)}ms)`);
      results.push({ endpoint: name, ok: true, status: res.status, latency: res.timings.duration });
    }
    return res;
  }

  function parse<T>(res: RefinedResponse<ResponseType>): T | null {
    if (res.status < 200 || res.status >= 300) return null;
    try { return JSON.parse(res.body as string) as T; } catch { return null; }
  }

  // ── TEACHER ──
  console.log('\n========== TEACHER PROBE ==========\n');
  const tC = new ApiClient(tokens.teacher, undefined, namePrefix);
  const tH = new HealthService(tC); const tA = new AuthService(tC);
  const tCl = new ClassService(tC); const tAs = new AssessmentService(tC);
  const tAt = new AssignmentService(tC); const tG = new GradingService(tC);
  const tM = new MaterialService(tC); const tT = new TosService(tC);
  const tS = new SyncService(tC);

  call('Health:Check', () => tH.health());
  call('Health:Ready', () => tH.ready());
  call('Health:DatabaseId', () => tH.databaseId());
  call('Auth:Me', () => tA.me());
  call('Shared:ClassMetadata', () => tCl.metadata());
  call('Shared:AssessmentMetadata', () => tAs.metadata());

  const clR = call('Teacher:ClassList', () => tCl.list('Teacher'));
  const cls = parse<{ id: string }[]>(clR);
  const cId = cls?.[0]?.id ?? '';

  if (cId) {
    call('Teacher:ClassDetail', () => tCl.detail(cId, 'Teacher'));

    const alR = call('Teacher:AssessmentList', () => tAs.list(cId, 'Teacher'));
    const als = parse<{ id: string }[]>(alR);
    const asmt = als?.[0];

    if (asmt) {
      call('Teacher:AssessmentDetail', () => tAs.detail(asmt.id, 'Teacher'));
      call('Teacher:AssessmentStats', () => tAs.getStatistics(asmt.id));
      call('Teacher:AssessmentSubmissions', () => tAs.getSubmissions(asmt.id));
    }

    const atlR = call('Teacher:AssignmentList', () => tAt.list(cId, 'Teacher'));
    const atls = parse<{ id: string }[]>(atlR);
    const asgn = atls?.[0];

    if (asgn) {
      call('Teacher:AssignmentDetail', () => tAt.detail(asgn.id, 'Teacher'));
      call('Teacher:AssignmentSubmissions', () => tAt.getSubmissions(asgn.id, { expectedStatuses: [200, 404] }));
    }

    call('Teacher:GradingConfig', () => tG.getConfig(cId));
    call('Teacher:GradeItems', () => tG.getGradeItems(cId));
    call('Teacher:Grades', () => tG.getGrades(cId));
    call('Teacher:GradeSummary', () => tG.getGradeSummary(cId));
    call('Teacher:FinalGrades', () => tG.getFinalGrades(cId));
    call('Teacher:GeneralAverages', () => tG.getGeneralAverages(cId, { timeout: '30s' }), { skipThrow: true });
    call('Teacher:DepedPresets', () => tG.getDepedPresets());

    const giR = call('Teacher:GradeItems', () => tG.getGradeItems(cId));
    const gis = parse<{ id: string }[]>(giR);
    if (gis?.[0]) call('Teacher:ItemScores', () => tG.getItemScores(gis[0].id));

    const tosR = call('Teacher:TosList', () => tT.list(cId));
    const tosl = parse<{ id: string }[]>(tosR);
    if (tosl?.[0]) call('Teacher:TosDetail', () => tT.detail(tosl[0].id));
    call('Teacher:MelcsSearch', () => tT.searchMelcs('science'));

    const mlR = call('Teacher:MaterialList', () => tM.list(cId, 'Teacher'));
    const mls = parse<{ id: string }[]>(mlR);
    call('Shared:MaterialMetadata', () => tM.metadata());
    if (mls?.[0]) call('Teacher:MaterialDetail', () => tM.detail(mls[0].id, 'Teacher'));

    call('Teacher:AllGradeData', () => tG.getGradeData(cId));
    if (students[0]) {
      call('Teacher:SF9', () => tG.getSf9(cId, students[0].id));
      call('Teacher:SF10', () => tG.getSf10(cId, students[0].id));
    }
  }

  if (students[0] && cId) {
    call('SyncPush:TeacherGrade', () => tS.push(fakeGradeScorePush(cId, students[0].id) as any));
  }

  // ── STUDENT ──
  console.log('\n========== STUDENT PROBE ==========\n');
  const sC = new ApiClient(tokens.student, undefined, namePrefix);
  const sH = new HealthService(sC); const sA = new AuthService(sC);
  const sCl = new ClassService(sC); const sAs = new AssessmentService(sC);
  const sAt = new AssignmentService(sC); const sG = new GradingService(sC);
  const sM = new MaterialService(sC); const sS = new SyncService(sC);

  call('Health:Check', () => sH.health());
  call('Auth:Me', () => sA.me());

  const sclR = call('Student:ClassList', () => sCl.list('Student'));
  const scls = parse<{ id: string }[]>(sclR);
  const scId = scls?.[0]?.id ?? '';

  if (scId) {
    call('Student:ClassDetail', () => sCl.detail(scId, 'Student'));

    call('Student:AssignmentList', () => sAt.studentList());
    const salR = call('Student:AssignmentDetail', () => sAt.list(scId, 'Student'));
    const sals = parse<{ id: string }[]>(salR);
    if (sals?.[0]) {
      call('Student:AssignmentDetail', () => sAt.detail(sals[0].id, 'Student'));
    }

    call('Student:MyGrades', () => sG.getMyGrades(scId));
    call('Student:MyTermGrades', () => sG.getMyTermGrades(scId, '1'));

    const smlR = call('Student:MaterialList', () => sM.list(scId, 'Student'));
    const smls = parse<{ id: string }[]>(smlR);
    if (smls?.[0]) call('Student:MaterialDetail', () => sM.detail(smls[0].id, 'Student'));

    const sasR = call('Student:AssessmentList', () => sAs.list(scId, 'Student'));
    const sasl = parse<{ id: string }[]>(sasR);
    if (sasl?.[0]) {
      call('Student:AssessmentDetail', () => sAs.detail(sasl[0].id, 'Student'));
    }
  }

  if (publishedAssessments[0] && students[0]) {
    call('SyncPush:StudentSubmission', () => sS.push(fakeAssessmentSubmissionServerPush(publishedAssessments[0].id, students[0].id) as any));
  }

  // ── ADMIN ──
  console.log('\n========== ADMIN PROBE ==========\n');
  const aC = new ApiClient(tokens.admin, undefined, namePrefix);
  const aAd = new AdminService(aC);

  call('Admin:AccountList', () => aAd.listAccounts());
  if (manifest.users[0]) {
    call('Admin:AccountDetail', () => aAd.getAccount(manifest.users[0].id));
    call('Admin:ActivityLogs', () => aAd.getActivityLogs(manifest.users[0].id));
  }
  call('Admin:SetupQr', () => aAd.getQrCode());
  call('Admin:SetupCode', () => aAd.getSchoolCode());
  call('Admin:SchoolSettings', () => aAd.getSchoolSettings());
  call('Admin:StudentSearch', () => aAd.searchStudents('student'));

  // ── SYNC ──
  console.log('\n========== SYNC PROBE ==========\n');
  const devId = 'probe_device_001';
  const lastSync = new Date(Date.now() - 5 * 60 * 1000).toISOString();

  call('Sync:Delta', () => tS.deltaSync({ device_id: devId, last_sync_at: lastSync }, { timeout: '30s' }), { skipThrow: true });
  call('Sync:Full', () => tS.fullSync(devId, activeClasses.map(c => c.id), { timeout: '30s' }), { skipThrow: true });

  // ── SUMMARY ──
  console.log('\n========== PROBE SUMMARY ==========\n');
  const fails = results.filter(r => !r.ok);
  console.log(`Total: ${results.length} | Failures: ${fails.length} | OK: ${results.length - fails.length}`);
  if (fails.length) {
    console.log('\nFailed endpoints:');
    fails.forEach(f => console.log(`  ${f.endpoint}: status=${f.status} error=${f.error || '-'} body=${f.body?.substring(0, 100) || '-'}`));
  } else {
    console.log('All endpoints passed.');
  }

  return results;
}

export function runDiagnosticProbeNoThrow(
  tokens: { teacher: string; student: string; admin: string },
  namePrefix?: string,
): ProbeResult[] {
  return runDiagnosticProbe(tokens, { noThrow: true, namePrefix });
}
