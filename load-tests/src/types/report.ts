export interface EndpointMetrics {
  name: string;
  count: number;
  failCount: number;
  failRate: number;
  min: number;
  avg: number;
  med: number;
  p10: number;
  p20: number;
  p30: number;
  p40: number;
  p50: number;
  p60: number;
  p70: number;
  p80: number;
  p90: number;
  p95: number;
  p99: number;
  max: number;
}

export interface ThresholdResult {
  metric: string;
  rule: string;
  passed: boolean;
  actual: string | number;
}

export interface ErrorDistribution {
  status: number | string;
  count: number;
  percentage: number;
}

export interface ScenarioReport {
  meta: {
    scenario: string;
    timestamp: string;
    duration: string;
    maxVus: number;
    totalRequests: number;
    failedRate: number;
    throughput: number;
    dataReceived: string;
    dataSent: string;
    passed: boolean;
    p95: number;
  };
  endpoints: EndpointMetrics[];
  thresholds: ThresholdResult[];
  errors: ErrorDistribution[];
  previousRun?: {
    timestamp: string;
    p95: number;
    errorRate: number;
    throughput: number;
  };
}

export interface HistoryEntry {
  scenario: string;
  timestamp: string;
  p95: number;
  errorRate: number;
  throughput: number;
  totalRequests: number;
}
