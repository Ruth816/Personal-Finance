// Shared by the api/ functions. Files starting with "_" are not deployed as their own endpoints.

// True when the request carries a valid sign-in for this app's Supabase project.
export async function isSignedIn(req) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ') || !process.env.SUPABASE_URL) return false;
  try {
    const r = await fetch(process.env.SUPABASE_URL.replace(/\/$/, '') + '/auth/v1/user', {
      headers: { Authorization: auth, apikey: process.env.SUPABASE_ANON_KEY || '' },
    });
    return r.ok;
  } catch {
    return false;
  }
}

export const list = (v, max) => (Array.isArray(v) ? v.slice(0, max).map((s) => String(s).slice(0, 160)) : []);
