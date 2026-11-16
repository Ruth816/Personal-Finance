# Ruth's Expenses Log: Specification

Version 1, 16 November 2026

## 1. Purpose

A personal web app for one person to log daily expenses, see where the money went by account and by day, and compare actual spending against a monthly budget. It is built from the workbook `RUTH PERSONAL FINANCE WORKFLOW INSTRUCTIONS.xlsx` (sheets: *expenses log sample*, *workflow*, *other instructions*).

## 2. Scope

In scope for version 1:

- Logging, editing and deleting expenses
- Remembering earlier descriptions and filling in their details
- Adding expenses from a receipt photo or from a CSV/Excel file
- Summaries per account, per day and per category
- Budget versus actual, with variance and an over-budget indicator

Not in version 1:

- Income, savings, transfers between accounts, account balances
- Separate budgets for each month (one budget per category applies to every month)
- Adding or renaming categories and accounts inside the app
- Exporting data to a file
- More than one user

## 3. Pages

The app has a header and four pages. The header shows a month stepper (previous / next), the total spent in the selected month, the number of items, and a save status line. Every page shows the month selected in the header.

| Page | Address | What it answers |
|---|---|---|
| Expenses log | `#log` | What did I spend, item by item? |
| Accounts | `#accounts` | How much have I spent from each account? |
| Daily breakdown | `#daily` | How much did I spend each day this month? |
| Budget tracking | `#budget` | Am I within budget in each category? |

## 4. Expenses log

### 4.1 Fields

| # | Field | Input | Rules |
|---|---|---|---|
| 1 | Item number | Automatic | Runs 01, 02, 03… within the month, in date order |
| 2 | Date | Date picker | Required. The day name (for example "Monday") shows under the field; the log shows "Mon 16 Nov" |
| 3 | Category | Dropdown, grouped | Required. See section 9 |
| 4 | Description | Text, up to 120 characters | Required. Suggests earlier entries while typing (section 5) |
| 5 | Amount | Number, pesos | Required, more than zero, stored to 2 decimals |
| 6 | Account | Dropdown | Required. See section 10 |
| 7 | Notes | Text, up to 200 characters | Optional |

### 4.2 Actions

- **Add item**: saves the entry, keeps the date and account for the next entry, and jumps to the month of the entry.
- **Edit**: loads the entry into the form; "Save changes" replaces it. Changing the date can move it to another month.
- **Delete**: removes the entry at once and offers "Undo" for 7 seconds.
- **Search**: filters the log by text in the description or notes.
- **Account filter**: shows only one account's items. The total row then shows the total of the items shown.

## 5. Auto-remember

- The app builds its memory from all saved entries. No separate list is kept.
- While typing a description, up to 6 matching earlier descriptions appear, with their category and account. Descriptions that start with the typed text come first, then the most used.
- Picking a suggestion fills in the description, category and account, and the last amount if the amount field is empty.
- If a description that exactly matches an earlier one is typed without picking a suggestion, the category and account are still filled in when leaving the field, provided they are empty.
- Arrow keys, Enter and Escape work in the suggestion list.

## 6. Upload by photo or file

### 6.1 Receipt photo

- "Scan a receipt photo" lets the user pick or take a photo.
- Claude reads the image and returns the date, a short description, the total paid, a suggested category, the account (only if the payment method is clearly shown) and a note.
- If the description matches an earlier entry, the remembered category and account take priority over Claude's suggestion.
- The result fills in the form. Nothing is saved until the user checks it and presses "Add item".
- The first use asks for permission to use Claude, and each scan counts against the user's Claude usage.
- The button is hidden where receipt reading is not available.

### 6.2 File import

- Accepts `.csv`, `.xlsx` and `.xls`.
- The file needs a date column and an amount column. Description, category, account and notes are optional. Columns are found by their header names, which may be anywhere in the first 15 rows. With no headers, the app assumes the order of the *expenses log sample* sheet (item number, date, category, description, amount, account, notes) or date, description, amount, category, account, notes.
- Dates are read as year-month-day, month/day/year (day/month/year when the first number is above 12), or written out ("Nov 16, 2026").
- Category and account are matched to the lists by name; otherwise they are filled from memory (section 5); otherwise left blank.
- Imported rows appear in a review table first. Each row needs a category and an account before it can be added. Choosing one for a row applies it to other rows with the same description that are still blank.
- "Add these to the log" adds the complete rows and keeps incomplete ones for fixing. Up to 300 rows per import.

## 7. Accounts page

- **Spent per account**: for the selected month, every account with its total, number of items, share of the month and a bar. "See items" opens the log filtered to that account.
- **Month by month**: a table of accounts (rows) by January to December (columns) for the selected year, with a year total per account and a total per month. The selected month is highlighted.

## 8. Daily breakdown page

- Four figures: month total, average per day (over the days elapsed so far in the current month), highest day, and days with spending.
- A bar chart with one bar per day of the month. Today is emphasised.
- A day-by-day list of each day with spending, showing its total and item count. Opening a day shows its items with category and account.

## 9. Budget tracking page

For each category in the selected month:

| Column | Meaning |
|---|---|
| Budget | Typed by the user; a monthly amount |
| Actual | Sum of logged expenses in that category |
| Variance | Budget − actual. Negative figures are red |
| % of spending | The category's share of the month's total spending |
| Status | "Over by ₱x" in red when actual is above budget; "On track" in green when within budget; "No budget set" when there is spending but no budget |

- Categories over budget also get a red stripe on the row.
- Each category group has a subtotal row with the same columns.
- A total row and four figures at the top: budget, actual, variance, and number of categories over budget.
- Budgets save when the user leaves the field.

## 10. Categories

Ten groups, 52 categories. A few names were tidied from the workbook (for example "Household maintenance", "Gifts & tithings").

| Group | Categories |
|---|---|
| Fixed expenses | Electric; Water; Phone & internet; Gas; Assoc dues; Helper; Household shopping; Household maintenance; Pet expenses; Property tax; Property insurance |
| Food | Groceries; Wet market; Meals (take out, dining & café); Reserved |
| Transportation | Fuel; Parking fees; Maintenance & repairs; Insurance; Registration; Public transport |
| Medical & insurance | Doctor's visit; Medication; Other (hospitalization); Life insurance; Health insurance |
| Happiness, health & wellness | Memberships & sports; Regular shopping spree; Wellness expenses (spa, treatments package & grooming); Vitamins & supplements |
| Kids & education | Allowances; Tuition fees; Books & materials; School travel/events expenses; Kids shopping expenses |
| Entertainment | Movies; Concert/events; Leisure travel with friends; Parties & gifts; Wine & dine with friends |
| Social responsibilities | Emergency cash assistance; Sponsorship (tuition fee/allowance); Parents support; Gifts & tithings |
| Big ticket expenses | Travel; Furniture, fixtures & equipment; Signature bag, watch & shoes; Cars; Renovations |
| Other: official only | Meals with staff & customers; Apps subscription; Office matters expenses |

## 11. Accounts

Cash; GCash; BDO Personal; UnionBank Personal; BPI Joint Account; BDO Joint Account; Rewards Platinum Mastercard; Cashback Platinum Mastercard; BDO Platinum Mastercard; BPI Visa Signature.

## 12. Data and storage

### 12.1 Expense record

| Field | Type | Example |
|---|---|---|
| `id` | text, unique | `mb3k2x9a4f` |
| `date` | `YYYY-MM-DD` | `2026-11-16` |
| `cat` | category id | `groceries` |
| `desc` | text | `Supermarket run` |
| `amt` | number, 2 decimals | `3620.75` |
| `acct` | account name | `GCash` |
| `notes` | text | `` |
| `ts` | time created, used to order items on the same day | `1794838089000` |

### 12.2 Where it is kept

- Saved to the user's Claude account, in a private area of the app's data store that only that user can read.
- One document per month (`m_YYYY-MM`, holding that month's items) and one document for budgets (`budget`, holding an amount per category id).
- If the account store cannot be reached when the page opens, the app saves in the browser instead and says so in the status line. Those entries stay on that device.
- Changes made on two devices at the same moment to the same month: the last save wins.

### 12.3 Status line

| Message | Meaning |
|---|---|
| Saved to your Claude account, private to you | All changes are stored |
| Saving… | A change is being stored |
| Saved in this browser only, not synced to your other devices | Fallback storage is in use |
| Could not save your last change… | The last change was not stored; edit it again |

## 13. Other behaviour

- **Currency**: Philippine peso (₱), two decimals.
- **Example entries**: while nothing has been logged, every page shows 12 marked example entries and example budgets. They are never saved and disappear with the first real entry.
- **Display**: follows the light or dark theme of the viewer; works at phone width, with wide tables scrolling sideways inside their own frame.
- **Receipt reading** needs the published app opened inside Claude; a plain HTML preview does not offer it.

## 14. Requirement check

| Source | Requirement | Where |
|---|---|---|
| workflow 1 | Item column with an add item button | 4.1, 4.2 |
| workflow 2 | Date with day | 4.1 |
| workflow 3 | Category dropdown with the listed groups | 4.1, 10 |
| workflow 4 | Description suggests what was encoded before | 5 |
| workflow 5 | Amount as encoded | 4.1 |
| workflow 6 | Account dropdown | 4.1, 11 |
| workflow 7 | Notes for remarks | 4.1 |
| other 1 | Summary of expenses per account | 7 |
| other 2 | Per-month total for each account | 7 |
| other 3 | Daily spending breakdown covering the month | 8 |
| other 4 | Upload by photo or file, auto-fill from earlier entries | 5, 6 |
| other 5 | Expense tracking with category percentages, budget, actual, variance, red indicator when over | 9 |

## 15. Open questions

1. Should budgets be set separately for each month (for yearly items such as property tax)?
2. Should the app also track income and account balances?
3. Should categories and accounts be editable inside the app?
4. Does "titings" mean tithings, or something else?
5. Is a file export (CSV or Excel) of the log needed?
