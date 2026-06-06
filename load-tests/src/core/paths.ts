/**
 * Path utilities for report generation
 * Generates timestamped file paths for per-scenario reports
 */

/**
 * Sanitize ISO timestamp for filesystem-safe filename
 * Replaces colons with hyphens: 2025-06-06T08:51:25.274Z -> 2025-06-06T08-51-25.274Z
 */
export function sanitizeTimestamp(timestamp: string): string {
  return timestamp.replace(/:/g, '-');
}

/**
 * Get the relative path for a scenario report file
 * Format: reports/{scenario}/{scenario}-{sanitized-timestamp}.json
 */
export function getReportPath(scenario: string, timestamp: string): string {
  const safeTs = sanitizeTimestamp(timestamp);
  return `reports/${scenario}/${scenario}-${safeTs}.json`;
}

/**
 * Get the relative path for the index manifest file
 */
export function getIndexPath(): string {
  return 'reports/index.json';
}

/**
 * Parse a report filename to extract scenario and timestamp
 * Returns null if filename doesn't match expected pattern
 */
export function parseReportFilename(
  filename: string
): { scenario: string; timestamp: string } | null {
  // Match pattern: {scenario}-{timestamp}.json
  // Timestamp format: YYYY-MM-DDTHH-MM-SS.mmmZ (sanitized ISO)
  const match = filename.match(/^(.+)-(\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.\d{3}Z)\.json$/);
  if (!match) return null;

  const [, scenario, safeTs] = match;
  // Convert back to ISO format with colons
  const timestamp = safeTs.replace(/-(\d{2})-(\d{2})-(\d{2})/, ':$1:$2:$3');

  return { scenario, timestamp };
}
