export async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, { headers: { "Content-Type": "application/json" }, ...init });
  if (!res.ok) { const body = await res.text(); throw new Error(`API ${res.status}: ${body}`); }
  return res.json();
}
