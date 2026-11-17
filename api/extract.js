// Reads a photo, PDF or Word document text with Claude and returns every expense in it,
// for the "Check the imported items" table. Only signed-in users of this app can call it.
import Anthropic from '@anthropic-ai/sdk';
import { isSignedIn, list } from './_auth.js';

const MAX_B64 = 4_000_000; // Vercel request bodies are limited to 4.5 MB
const MAX_TEXT = 150_000;
const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const ITEMS_SCHEMA = {
  type: 'object',
  properties: {
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          date: { anyOf: [{ type: 'string' }, { type: 'null' }] },
          description: { type: 'string' },
          amount: { type: 'number' },
          category: { anyOf: [{ type: 'string' }, { type: 'null' }] },
          account: { anyOf: [{ type: 'string' }, { type: 'null' }] },
          notes: { type: 'string' },
        },
        required: ['date', 'description', 'amount', 'category', 'account', 'notes'],
        additionalProperties: false,
      },
    },
  },
  required: ['items'],
  additionalProperties: false,
};

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });
  if (!process.env.ANTHROPIC_API_KEY) return res.status(503).json({ error: 'scan_unavailable' });
  if (!(await isSignedIn(req))) return res.status(401).json({ error: 'not_signed_in' });

  const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
  const { kind, data, mediaType, today, fileName } = body;

  let source;
  if (kind === 'image' && typeof data === 'string' && data && data.length <= MAX_B64 && IMAGE_TYPES.includes(mediaType)) {
    source = { type: 'image', source: { type: 'base64', media_type: mediaType, data } };
  } else if (kind === 'pdf' && typeof data === 'string' && data && data.length <= MAX_B64) {
    source = { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data } };
  } else if (kind === 'text' && typeof data === 'string' && data.trim() && data.length <= MAX_TEXT) {
    source = { type: 'text', text: '<document>\n' + data + '\n</document>' };
  } else {
    return res.status(400).json({ error: 'file_rejected' });
  }

  const cats = list(body.categories, 80);
  const accts = list(body.accounts, 40);
  const day = /^\d{4}-\d{2}-\d{2}$/.test(today) ? today : new Date().toISOString().slice(0, 10);
  const name = typeof fileName === 'string' ? fileName.slice(0, 120) : '';

  const prompt =
    'The attached file is a receipt, bill, bank or credit card statement, or a list of expenses, most likely from the Philippines. ' +
    'List every expense in it: purchases, charges, bills, fees and interest. ' +
    'Leave out payments made to the card, credits, refunds, reversals, balances, totals and subtotals. ' +
    'A single receipt is one item: use its total, not its individual lines.\n' +
    'For each item give: date (YYYY-MM-DD, or null if not shown; if the year is missing, use the year that makes the date closest to, but not after, today); ' +
    'description (the merchant or item, as written, at most 120 characters); ' +
    'amount (a positive number in pesos; when both a foreign amount and a peso amount are shown, use the peso amount); ' +
    'category (one id from the category list, or null if unsure); ' +
    'account (one name from the account list, only if the card or payment method clearly matches it, else null); ' +
    'notes (a short remark such as the foreign currency amount or a reference number, or an empty string).\n' +
    `Today is ${day}.` + (name ? ` The file is named "${name}".` : '') + '\n' +
    `Category list (id = meaning): ${cats.join('; ')}.\n` +
    `Account list: ${accts.join('; ')}.`;

  const client = new Anthropic();
  try {
    const response = await client.beta.messages.create({
      model: 'claude-opus-5-5',
      max_tokens: 16000,
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      output_config: { effort: 'low', format: { type: 'json_schema', schema: ITEMS_SCHEMA } },
      messages: [{ role: 'user', content: [source, { type: 'text', text: prompt }] }],
    });

    if (response.stop_reason === 'refusal') return res.status(422).json({ error: 'unreadable' });
    if (response.stop_reason === 'max_tokens') return res.status(422).json({ error: 'too_long' });
    const text = response.content.find((b) => b.type === 'text')?.text;
    if (!text) return res.status(422).json({ error: 'unreadable' });
    return res.status(200).json(JSON.parse(text));
  } catch (err) {
    if (err instanceof Anthropic.RateLimitError) return res.status(429).json({ error: 'rate_limited' });
    if (err instanceof Anthropic.AuthenticationError) return res.status(503).json({ error: 'scan_unavailable' });
    if (err instanceof Anthropic.BadRequestError) return res.status(400).json({ error: 'file_rejected' });
    if (err instanceof Anthropic.APIError) return res.status(502).json({ error: 'upstream_error' });
    if (err instanceof SyntaxError) return res.status(422).json({ error: 'unreadable' });
    console.error(err);
    return res.status(500).json({ error: 'server_error' });
  }
}
