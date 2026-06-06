import { Stage } from 'k6/options';

export const stages = {
  baseline: [
    { duration: '30s', target: 25 },
    { duration: '2m', target: 50 },
    { duration: '30s', target: 0 },
  ] satisfies Stage[],

  stress: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 200 },
    { duration: '2m', target: 500 },
    { duration: '1m', target: 250 },
    { duration: '30s', target: 0 },
  ] satisfies Stage[],

  gradualRamp: (maxVu: number): Stage[] => [
    { duration: '1m', target: Math.floor(maxVu / 2) },
    { duration: '2m', target: maxVu },
    { duration: '30s', target: 0 },
  ],

  surge: (maxVu: number): Stage[] => [
    { duration: '10s', target: maxVu },
    { duration: '3m', target: maxVu },
    { duration: '10s', target: 0 },
  ],

  examSurge: [
    { duration: '5s', target: 70 },
    { duration: '5m', target: 70 },
    { duration: '10s', target: 0 },
  ] satisfies Stage[],
} as const;
