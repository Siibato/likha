import { createServer } from 'http';
import { readFileSync, existsSync, writeFileSync } from 'fs';
import { join, extname } from 'path';
import { spawn } from 'child_process';

const PORT = 3050;
const REPORTS_DIR = 'reports';
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

// Copy latest dashboard.html to reports on startup
const dashboardAssetPath = join(ASSETS_DIR, 'dashboard.html');
const dashboardServePath = join(REPORTS_DIR, 'index.html');
if (existsSync(dashboardAssetPath)) {
  const content = readFileSync(dashboardAssetPath);
  writeFileSync(dashboardServePath, content);
}

const server = createServer((req, res) => {
  const url = req.url === '/' ? '/index.html' : req.url;
  const cleanUrl = url.split('?')[0];

  res.setHeader('Access-Control-Allow-Origin', '*');

  if (cleanUrl === '/index.html') {
    serveFile(res, dashboardServePath);
    return;
  }

  const filePath = join(REPORTS_DIR, cleanUrl);
  serveFile(res, filePath);
});

server.listen(PORT, () => {
  console.log(`Dashboard server running at http://localhost:${PORT}`);

  // Open browser
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
