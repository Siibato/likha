import { Options } from 'k6/options';

type Thresholds = NonNullable<Options['thresholds']>;

export const thresholds = {
  strict: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.99'],
  } satisfies Thresholds,

  normal: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95'],
  } satisfies Thresholds,

  stress: {
    http_req_duration: ['p(95)<1000'],
    http_req_failed: ['rate<0.05'],
    checks: ['rate>0.90'],
  } satisfies Thresholds,

  sync: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95'],
  } satisfies Thresholds,
} as const;
