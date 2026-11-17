// Reads a receipt photo with Claude and returns the fields for the expense form.
// Only signed-in users of this app's Supabase project can call it.
import Anthropic from '@anthropic-ai/sdk';
import { isSignedIn, list } from './_auth.js';

const MAX_B64 = 4_000_000; // Vercel request bodies are limited to 4.5 MB
const MEDIA = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const RECEIPT_SCHEMA = {
  type: 'object',
  properties: {
    date: { anyOf: [{ type: 'string' }, { type: 'null' }] },
    description: { type: 'string' },
    amount: { anyOf: [{ type: 'number' }, { type: 'null' }] },
    category: { anyOf: [{ type: 'string' }, { type: 'null' }] },
    account: { anyOf: [{ type: 'string' }, { type: 'null' }] },
    notes: { type: 'string' },
  },
  required: ['date', 'description', 'amount', 'category', 'account', 'notes'],
  additionalProperties: false,
};

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
  if (!process.env.ANTHROPIC_API_KEY) return res.status(503).json({ error: 'scan_unavailable' });
  if (!(await isSignedIn(req))) return res.status(401).json({ error: 'not_signed_in' });

  const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
  const { image, mediaType, today } = body;
  if (typeof image !== 'string' || !image || image.length > MAX_B64 || !MEDIA.includes(mediaType)) {
    return res.status(400).json({ error: 'image_rejected' });
  }
  const cats = list(body.categories, 80);
  const accts = list(body.accounts, 40);
  const day = /^\d{4}-\d{2}-\d{2}$/.test(today) ? today : new Date().toISOString().slice(0, 10);

  const prompt =
    'The image is a receipt, bill or payment screenshot, most likely from the Philippines. ' +
    'Read it and fill in: date (YYYY-MM-DD, or null if not shown); description (short merchant or item name, at most 6 words); ' +
    'amount (the total paid, as a number in pesos, or null); category (one id from the category list, or null); ' +
    'account (one name from the account list, only if the payment method is clearly shown, else null); ' +
    'notes (a short remark such as a reference number, or an empty string).\n' +
    `Today is ${day}.\n` +
    `Category list (id = meaning): ${cats.join('; ')}.\n` +
    `Account list: ${accts.join('; ')}.`;

  const client = new Anthropic();
  try {
    const response = await client.beta.messages.create({
      model: 'claude-opus-5-5',
      max_tokens: 16000,
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      output_config: { effort: 'low', format: { type: 'json_schema', schema: RECEIPT_SCHEMA } },
      messages: [
        {
          role: 'user',
          content: [
            { type: 'image', source: { type: 'base64', media_type: mediaType, data: image } },
            { type: 'text', text: prompt },
          ],
        },
      ],
    });

    if (response.stop_reason === 'refusal') return res.status(422).json({ error: 'unreadable' });
    const text = response.content.find((b) => b.type === 'text')?.text;
    if (!text) return res.status(422).json({ error: 'unreadable' });
    return res.status(200).json(JSON.parse(text));
  } catch (err) {
    if (err instanceof Anthropic.RateLimitError) return res.status(429).json({ error: 'rate_limited' });
    if (err instanceof Anthropic.AuthenticationError) return res.status(503).json({ error: 'scan_unavailable' });
    if (err instanceof Anthropic.BadRequestError) return res.status(400).json({ error: 'image_rejected' });
    if (err instanceof Anthropic.APIError) return res.status(502).json({ error: 'upstream_error' });
    if (err instanceof SyntaxError) return res.status(422).json({ error: 'unreadable' });
    console.error(err);
    return res.status(500).json({ error: 'server_error' });
  }
}
