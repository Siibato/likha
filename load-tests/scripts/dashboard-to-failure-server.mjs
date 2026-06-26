import { createServer } from 'http';
import { readFileSync, existsSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, extname } from 'path';
import { spawn } from 'child_process';

const PORT = 3051;
const REPORTS_DIR = 'reports';
const SCENARIO_DIR = 'load-test-to-failure';
const ASSETS_DIR = 'src/assets';

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
};

/**
 * Parse a report filename to extract scenario and timestamp
 * Pattern: {scenario}-{timestamp}.json where timestamp has colons replaced with hyphens
 */
function parseReportFilename(filename) {
  const match = filename.match(/^(.+)-(\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.\d{3}Z)\.json$/);
  if (!match) return null;

  const [, scenario, safeTs] = match;
  const timestamp = safeTs.replace(/-(\d{2})-(\d{2})-(\d{2})/, ':$1:$2:$3');

  return { scenario, timestamp };
}

/**
 * Scan only the load-test-to-failure reports directory
 */
function generateManifest() {
  const reports = [];

  try {
    const scenarioPath = join(REPORTS_DIR, SCENARIO_DIR);
    if (!existsSync(scenarioPath)) {
      return { generatedAt: new Date().toISOString(), reports: [] };
    }

    const stat = statSync(scenarioPath);
    if (!stat.isDirectory()) {
      return { generatedAt: new Date().toISOString(), reports: [] };
    }

    const files = readdirSync(scenarioPath);

    for (const file of files) {
      if (!file.endsWith('.json')) continue;

      const parsed = parseReportFilename(file);
      if (!parsed) continue;

      reports.push({
        scenario: parsed.scenario,
        timestamp: parsed.timestamp,
        path: `${SCENARIO_DIR}/${file}`,
      });
    }
  } catch (err) {
    console.warn('Warning: Could not scan reports directory:', err.message);
  }

  reports.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

  return {
    generatedAt: new Date().toISOString(),
    reports,
  };
}

function writeManifest() {
  const manifest = generateManifest();
  const manifestPath = join(REPORTS_DIR, 'load-test-to-failure-index.json');

  try {
    writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  } catch (err) {
    console.error('Error writing manifest:', err.message);
  }
  return manifest;
}

function serveFile(res, filePath) {
  if (!existsSync(filePath)) {
    res.writeHead(404);
    res.end('Not found');
    return;
  }
  const ext = extname(filePath);
  const contentType = MIME[ext] || 'application/octet-stream';
  const content = readFileSync(filePath);
  res.writeHead(200, {
    'Content-Type': contentType,
    'Content-Length': content.length,
  });
  res.end(content);
}

function serveJson(res, data) {
  const content = JSON.stringify(data, null, 2);
  res.writeHead(200, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(content),
  });
  res.end(content);
}

// Copy latest dashboard-to-failure.html to reports on startup
const dashboardAssetPath = join(ASSETS_DIR, 'dashboard-to-failure.html');
const dashboardServePath = join(REPORTS_DIR, 'load-test-to-failure.html');
if (existsSync(dashboardAssetPath)) {
  const content = readFileSync(dashboardAssetPath);
  writeFileSync(dashboardServePath, content);
}

// Generate initial manifest
writeManifest();

const server = createServer((req, res) => {
  const url = req.url === '/' ? '/load-test-to-failure.html' : req.url;
  const cleanUrl = url.split('?')[0];

  res.setHeader('Access-Control-Allow-Origin', '*');

  if (cleanUrl === '/load-test-to-failure.html') {
    serveFile(res, dashboardServePath);
    return;
  }

  if (cleanUrl === '/api/manifest') {
    const manifest = generateManifest();
    serveJson(res, manifest);
    return;
  }

  // Serve files from reports directory (including subdirectories)
  const filePath = join(REPORTS_DIR, cleanUrl);
  serveFile(res, filePath);
});

server.listen(PORT, () => {
  console.log(`Load-Test-to-Failure Dashboard running at http://localhost:${PORT}`);

  const platform = process.platform;
  const url = `http://localhost:${PORT}`;
  if (platform === 'darwin') {
    spawn('open', [url], { stdio: 'ignore', detached: true });
  } else if (platform === 'win32') {
    spawn('start', [url], { stdio: 'ignore', detached: true, shell: true });
  } else {
    spawn('xdg-open', [url], { stdio: 'ignore', detached: true });
  }
});
