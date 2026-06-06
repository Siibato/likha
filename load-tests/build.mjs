import { build } from 'esbuild';
import { readdirSync, copyFileSync } from 'fs';
import { join } from 'path';

const scenarioDir = './src/scenarios';
const outDir = './dist';

const entryPoints = readdirSync(scenarioDir)
  .filter((f) => f.endsWith('.ts'))
  .map((f) => join(scenarioDir, f));

console.log(`Building ${entryPoints.length} scenarios: ${entryPoints.map((e) => e.split('/').pop()).join(', ')}`);

await build({
  entryPoints,
  bundle: true,
  outdir: outDir,
  outExtension: { '.js': '.js' },
  format: 'esm',
  platform: 'browser',
  target: 'es2020',
  external: ['k6', 'k6/*'],
  sourcemap: false,
  minify: false,
  logLevel: 'info',
});

copyFileSync('seed-manifest.json', join(outDir, 'seed-manifest.json'));
console.log(`Build complete → ${outDir}/`);
