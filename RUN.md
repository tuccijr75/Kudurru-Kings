# KudurruKings — Open Package

## Prereqs
- Node.js 18+ (Node 20 recommended)
- Optional: Postgres (if you enable persistence); otherwise it runs in-memory.

## Quick Start
```bash
npm install
npm run dev
# open http://localhost:5000/lobby  (or http://localhost:5173 if your client dev server boots)
```

## Environment (optional)
Create a `.env` file at project root for these:
```
PRIORITY_TIMEOUT_MS=20000
DATABASE_URL=postgres://user:pass@host/db   # if you wire persistence
JWT_SECRET=change-me
```

## What’s included
- server/ (Express + WS)
- client/ (React app)
- shared/ (types/specs)
- tests/ (Vitest & Playwright stubs, if present)

If `npm run dev` fails on your machine, try:
```bash
node server/index.js
```