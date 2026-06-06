import { check } from 'k6';
import { RefinedResponse, ResponseType } from 'k6/http';

export type CheckResult = boolean;

export function expectStatus(
  res: RefinedResponse<ResponseType>,
  status: number,
  label: string,
): CheckResult {
  return check(res, {
    [`${label}: status ${status}`]: (r) => r.status === status,
  });
}

export function expectStatus2xx(
  res: RefinedResponse<ResponseType>,
  label: string,
): CheckResult {
  return check(res, {
    [`${label}: status 2xx`]: (r) => r.status >= 200 && r.status < 300,
  });
}

export function expectUnder(
  res: RefinedResponse<ResponseType>,
  ms: number,
  label: string,
): CheckResult {
  return check(res, {
    [`${label}: response < ${ms}ms`]: (r) => r.timings.duration < ms,
  });
}

export function expectNoServerError(
  res: RefinedResponse<ResponseType>,
  label: string,
): CheckResult {
  return check(res, {
    [`${label}: no 5xx`]: (r) => r.status < 500,
  });
}

export function expectAll(
  res: RefinedResponse<ResponseType>,
  label: string,
  opts: { status?: number; underMs?: number } = {},
): CheckResult {
  const { status = 200, underMs = 500 } = opts;
  const statusOk = check(res, {
    [`${label}: status ${status}`]: (r) => r.status === status,
  });
  const speedOk = check(res, {
    [`${label}: response < ${underMs}ms`]: (r) => r.timings.duration < underMs,
  });
  return statusOk && speedOk;
}
