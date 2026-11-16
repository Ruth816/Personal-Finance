// Runs the app on your computer at http://localhost:3000 (npm run dev).
// Serves public/ and the functions in api/ the same way Vercel does.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
try { process.loadEnvFile(path.join(here, '.env.local')); } catch { /* no .env.local: runs in browser-only mode */ }

const PORT = Number(process.env.PORT) || 3000;
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon' };

function addHelpers(res) {
  res.status = (code) => { res.statusCode = code; return res; };
  res.json = (obj) => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(obj)); return res; };
  return res;
}

async function readBody(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  const raw = Buffer.concat(chunks).toString('utf8');
  try { return raw ? JSON.parse(raw) : {}; } catch { return raw; }
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  try {
    if (url.pathname.startsWith('/api/')) {
      const name = url.pathname.slice(5).replace(/[^a-z0-9_-]/gi, '');
      const file = path.join(here, 'api', name + '.js');
      const mod = await import(pathToFileURL(file).href);
      req.body = req.method === 'POST' ? await readBody(req) : undefined;
      return await mod.default(req, addHelpers(res));
    }
    const rel = url.pathname === '/' ? 'index.html' : decodeURIComponent(url.pathname).replace(/^\/+/, '');
    const file = path.join(here, 'public', rel);
    if (!file.startsWith(path.join(here, 'public'))) { res.writeHead(403); return res.end(); }
    const data = await fs.readFile(file);
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  } catch (e) {
    if (e.code === 'ENOENT' || e.code === 'ERR_MODULE_NOT_FOUND') { res.writeHead(404); return res.end('Not found'); }
    console.error(e);
    res.writeHead(500); res.end('Server error');
  }
}).listen(PORT, () => {
  console.log(`Ruth's Expenses Log running at http://localhost:${PORT}`);
  console.log(process.env.SUPABASE_URL ? 'Supabase: configured' : 'Supabase: not configured (browser-only mode)');
});
