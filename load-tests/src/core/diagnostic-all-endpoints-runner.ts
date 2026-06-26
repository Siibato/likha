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
import { activeClasses, publishedAssessments, publishedAssignments, students, manifest } from '../data/manifest';

export interface ProbeResult { endpoint: string; ok: boolean; status: number; latency: number; body?: string; error?: string; }

export function runAllEndpointsProbe(tokens: { teacher: string; student: string; admin: string }): ProbeResult[] {
  const results: ProbeResult[] = [];

  function call(name: string, fn: () => RefinedResponse<ResponseType>, opts?: { skipThrow?: boolean }): RefinedResponse<ResponseType> {
    console.log(`→ ${name}`);
    const res = fn();
    const ok = res.status >= 200 && res.status < 300 && !res.error;
    const bodyPreview = typeof res.body === 'string' ? res.body.substring(0, 300) : '';
    if (!ok) {
      console.log(`  FAIL status=${res.status} error=${res.error || ''} body=${bodyPreview}`);
      results.push({ endpoint: name, ok: false, status: res.status, latency: res.timings.duration, body: bodyPreview, error: res.error || '' });
      if (!opts?.skipThrow) {
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

  const cId = activeClasses[0]?.id ?? '';
  const asmt = publishedAssessments[0] ?? null;
  const asgn = publishedAssignments[0] ?? null;

  // ── TEACHER ──
  console.log('\n========== TEACHER PROBE ==========\n');
  const tC = new ApiClient(tokens.teacher);
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

  call('Teacher:ClassList', () => tCl.list('Teacher'));
  if (cId) {
    call('Teacher:ClassDetail', () => tCl.detail(cId, 'Teacher'));

    call('Teacher:AssessmentList', () => tAs.list(cId, 'Teacher'));
    if (asmt) {
      call('Teacher:AssessmentDetail', () => tAs.detail(asmt.id, 'Teacher'));
      call('Teacher:AssessmentStats', () => tAs.getStatistics(asmt.id));
      call('Teacher:AssessmentSubmissions', () => tAs.getSubmissions(asmt.id, { expectedStatuses: [200, 404] }));
    }

    call('Teacher:AssignmentList', () => tAt.list(cId, 'Teacher'));
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

    call('Teacher:TosList', () => tT.list(cId));
    const tosl = parse<{ id: string }[]>(call('Teacher:TosList', () => tT.list(cId)));
    if (tosl?.[0]) call('Teacher:TosDetail', () => tT.detail(tosl[0].id));
    call('Teacher:MelcsSearch', () => tT.searchMelcs('science'));

    call('Teacher:MaterialList', () => tM.list(cId, 'Teacher'));
    call('Shared:MaterialMetadata', () => tM.metadata());
    const ml = parse<{ id: string }[]>(call('Teacher:MaterialList', () => tM.list(cId, 'Teacher')));
    if (ml?.[0]) call('Teacher:MaterialDetail', () => tM.detail(ml[0].id, 'Teacher'));
  }

  // ── STUDENT ──
  console.log('\n========== STUDENT PROBE ==========\n');
  const sC = new ApiClient(tokens.student);
  const sH = new HealthService(sC); const sA = new AuthService(sC);
  const sCl = new ClassService(sC); const sAs = new AssessmentService(sC);
  const sAt = new AssignmentService(sC); const sG = new GradingService(sC);
  const sM = new MaterialService(sC); const sS = new SyncService(sC);

  call('Health:Check', () => sH.health());
  call('Auth:Me', () => sA.me());
  call('Student:ClassList', () => sCl.list('Student'));
  if (cId) {
    call('Student:ClassDetail', () => sCl.detail(cId, 'Student'));
    call('Student:AssignmentList', () => sAt.studentList());
    call('Student:Assignments', () => sAt.list(cId, 'Student'));
    if (asgn) {
      call('Student:AssignmentDetail', () => sAt.detail(asgn.id, 'Student'));
    }
    call('Student:MyGrades', () => sG.getMyGrades(cId));
    call('Student:MyTermGrades', () => sG.getMyTermGrades(cId, '1'));
    call('Student:MaterialList', () => sM.list(cId, 'Student'));
    const sml = parse<{ id: string }[]>(call('Student:MaterialList', () => sM.list(cId, 'Student')));
    if (sml?.[0]) call('Student:MaterialDetail', () => sM.detail(sml[0].id, 'Student'));
    if (asmt) {
      call('Student:AssessmentDetail', () => sAs.detail(asmt.id, 'Student'));
    }
  }

  // ── ADMIN ──
  console.log('\n========== ADMIN PROBE ==========\n');
  const aC = new ApiClient(tokens.admin);
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
  } else { console.log('All endpoints passed.'); }

  return results;
}
