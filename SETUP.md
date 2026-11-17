# Ruth's Expenses Log: setup

The app is a single page (`public/index.html`) hosted on **Vercel**, with your data in **Supabase**.
Two small server functions live in `api/`: `config.js` gives the page your Supabase address, and `scan.js` reads receipt photos with Claude (optional).

## 1. Supabase (about 5 minutes)

1. **Create the tables.** In your Supabase project open **SQL Editor → New query**, paste the whole of `supabase/schema.sql`, and press **Run**. It should say "Success. No rows returned".
2. **Create your login.** Go to **Authentication → Users → Add user → Create new user**. Enter your email and a password, and tick **Auto Confirm User**.
3. **Stop strangers signing up.** Go to **Authentication → Sign In / Providers** and turn **off** "Allow new users to sign up". Your existing login keeps working.
4. **Copy two values** from **Project Settings → API** (also shown under **Connect**):
   - **Project URL**, e.g. `https://abcdxyz.supabase.co`
   - **anon public** key (a long text starting `eyJ…` or `sb_publishable_…`)

   Do **not** use the `service_role` / secret key anywhere in this app.

## 2. Try it on your computer (optional)

1. Copy `.env.example` to a new file named `.env.local` and paste in the two values from step 1.4.
2. In this folder run:

   ```bash
   npm install
   ```

   ```bash
   npm run dev
   ```

3. Open http://localhost:3000 and sign in with the login from step 1.2.

Without `.env.local`, the app still runs but saves only in that browser.

## 3. Put the code on GitHub

Replace the address with your repository's address (GitHub → your repo → green **Code** button → HTTPS):

```bash
git remote add origin https://github.com/YOUR-NAME/YOUR-REPO.git
```

```bash
git push -u origin main
```

`.gitignore` keeps `.env.local` and all Excel files out of GitHub.

## 4. Deploy on Vercel

1. In Vercel choose **Add New → Project** and **Import** your GitHub repository.
2. **Framework Preset:** Other. Leave the build and output settings as they are (`vercel.json` already points to `public`).
3. Open **Environment Variables** and add:

   | Name | Value |
   |---|---|
   | `SUPABASE_URL` | Project URL from step 1.4 |
   | `SUPABASE_ANON_KEY` | anon public key from step 1.4 |
   | `ANTHROPIC_API_KEY` | optional, see step 5 |

4. Press **Deploy**. When it finishes, open the address Vercel gives you (e.g. `https://your-project.vercel.app`) and sign in.

From now on every `git push` to `main` redeploys the app automatically.

## 5. Receipt scanning and reading photos, PDFs and Word files (optional)

**Import a file** on the Expenses log page accepts:

| File | How it is read | Needs `ANTHROPIC_API_KEY` |
|---|---|---|
| Excel (.xlsx, .xls), CSV | In the browser | No |
| Word (.docx) with a table that has Date and Amount columns | In the browser | No |
| Word (.docx) without such a table | By Claude (`api/extract`) | Yes |
| PDF (up to about 2.9 MB, not password-protected), e.g. a card statement | By Claude (`api/extract`) | Yes |
| Photo of a receipt or statement | By Claude (`api/extract`) | Yes |

Every import goes to **Check the imported items**, where you pick any missing category or account before adding. Old `.doc` files must first be saved as `.docx`.

"Scan a receipt photo" (fills in the form for one receipt) appears only when `ANTHROPIC_API_KEY` is set in Vercel.

- Create a key at console.anthropic.com → **API keys**. It is billed separately from a Claude.ai subscription, per scan (each photo costs a few cents or less).
- After adding or changing an environment variable in Vercel, go to **Deployments → ⋯ → Redeploy** so it takes effect.
- Only someone signed in to your app can use the scan, so your key cannot be used by strangers.

## Differences from spec.md

| Spec | This build |
|---|---|
| 12.2: data saved to the Claude account, one document per month | Saved in Supabase, one row per expense (`expenses`) and one per budget (`budgets`), each protected so only your login can read or change it |
| 6.1: receipts read by Claude inside the Claude app, counted against Claude usage | Read by the `api/scan` function with your Anthropic API key, billed to that key |
| 6.2: import CSV or Excel | Also imports Word, PDF and photos (see step 5) |
| 12.3 status line "Saved to your Claude account…" | "Saved to your account, private to you" |
| — | Sign-in screen (email + password) and a **Sign out** link in the header |
| 12.2 two devices at once | Unchanged: last save wins. The app also reloads your data when you switch back to its tab |

The original `index.html` in the folder root is the earlier Claude-hosted version; Vercel serves `public/index.html` instead.
