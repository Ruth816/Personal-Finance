// Tells the browser how to reach Supabase and whether receipt scanning is switched on.
// The anon key is designed to be public; Row Level Security protects the data.
export default function handler(req, res) {
  const supabaseUrl = process.env.SUPABASE_URL || '';
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({
    supabaseUrl,
    supabaseAnonKey,
    scan: Boolean(process.env.ANTHROPIC_API_KEY && supabaseUrl && supabaseAnonKey),
  });
}
