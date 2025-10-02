// Lightweight launcher to support TS or JS server code
try {
  require('dotenv').config();
} catch {}
try {
  // If TS sources exist, use ts-node/register for dev
  if (require('fs').existsSync(__dirname + '/index.ts')) {
    require('ts-node/register');
    require('./index.ts');
  } else {
    require('./server.js'); // in case there is a compiled server.js
  }
} catch (e) {
  console.error("Failed to start server:", e);
  process.exit(1);
}