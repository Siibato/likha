import { Options, Stage } from 'k6/options';

type Thresholds = NonNullable<Options['thresholds']>;

export function buildOptions(
  stageList: Stage[],
  threshold: Thresholds,
): Options {
  return {
    stages: stageList,
    thresholds: threshold,
  };
}
