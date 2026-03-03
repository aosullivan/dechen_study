// Server-set anonymous ID for usage analytics. Issues anon_id and persists it in a cookie (web).
// GET: returns { anon_id } from cookie or generates and sets cookie. Requires Authorization: Bearer <anon_key>.

const COOKIE_NAME = 'usage_metrics_anon_id';
const COOKIE_MAX_AGE = 63072000; // 2 years
const ANON_ID_REGEX = /^a_[a-z0-9]+_[a-z0-9]+$/;

function corsHeaders(origin: string | null): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': origin ?? '*',
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, content-type',
    'Access-Control-Max-Age': '86400',
  };
}

function parseCookie(cookieHeader: string | null): string | null {
  if (!cookieHeader || !cookieHeader.trim()) return null;
  const prefix = `${COOKIE_NAME}=`;
  for (const part of cookieHeader.split(';')) {
    const trimmed = part.trim();
    if (trimmed.startsWith(prefix)) {
      const value = trimmed.slice(prefix.length).trim();
      return value.length > 0 ? value : null;
    }
  }
  return null;
}

function isValidAnonId(value: string): boolean {
  return ANON_ID_REGEX.test(value);
}

function generateAnonId(): string {
  const now = Date.now();
  const ms = now.toString(36);
  const arr = new Uint8Array(4);
  crypto.getRandomValues(arr);
  const r = Array.from(arr)
    .reduce((acc, b) => (acc << 8) | b, 0)
    .toString(36);
  return `a_${ms}_${r}`;
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get('Origin');

  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      status: 200,
      headers: corsHeaders(origin),
    });
  }

  if (req.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: {
        ...corsHeaders(origin),
        'Content-Type': 'application/json',
      },
    });
  }

  // Require auth header so only the app can call this
  const auth = req.headers.get('Authorization');
  if (!auth?.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing or invalid Authorization' }), {
      status: 401,
      headers: {
        ...corsHeaders(origin),
        'Content-Type': 'application/json',
      },
    });
  }

  const cookieHeader = req.headers.get('Cookie');
  const existing = parseCookie(cookieHeader);
  if (existing && isValidAnonId(existing)) {
    return new Response(JSON.stringify({ anon_id: existing }), {
      status: 200,
      headers: {
        ...corsHeaders(origin),
        'Content-Type': 'application/json',
      },
    });
  }

  const anonId = generateAnonId();
  const setCookie = `${COOKIE_NAME}=${anonId}; Path=/; Max-Age=${COOKIE_MAX_AGE}; SameSite=None; Secure; HttpOnly`;

  return new Response(JSON.stringify({ anon_id: anonId }), {
    status: 200,
    headers: {
      ...corsHeaders(origin),
      'Content-Type': 'application/json',
      'Set-Cookie': setCookie,
    },
  });
});
