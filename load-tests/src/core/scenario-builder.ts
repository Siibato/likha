import { Options, Stage } from 'k6/options';

type Thresholds = NonNullable<Options['thresholds']>;

export function buildOptions(
  stageList: Stage[],
  threshold: Thresholds,
  extraThresholds?: Thresholds,
): Options {
  return {
    stages: stageList,
    thresholds: { ...threshold, ...extraThresholds },
    summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(10)', 'p(20)', 'p(30)', 'p(40)', 'p(50)', 'p(60)', 'p(70)', 'p(80)', 'p(90)', 'p(95)', 'p(99)'],
  };
}
