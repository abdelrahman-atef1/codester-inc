# فاتورة (Fatura) — Stitch Designs · Bold Executive

Generated with Google Stitch on 2026-10-03. Mobile, Arabic RTL, Cairo font.

- Stitch project: `projects/5078004998862869715`
- Design system asset: `assets/14705778277479534960` ("Fatura — Bold Executive")

## Tokens
| Token | Value |
|---|---|
| Primary (actions, active tab, peak bar) | `#E63946` |
| Accent (success, in-stock, share, trends) | `#2A9D8F` |
| Background | `#F1F5F9` |
| Dark surface (top bars, cart, hero KPI) | `#1E293B` |
| Text / muted / border | `#0F172A` / `#64748B` / `#E2E8F0` |
| Warning (low stock) | `#F59E0B` |
| Font | Cairo — 800 numbers, 700 headers, 600 labels, 400 body |
| Radius | 8px, flat, 1px borders |

## Screens
| File | Stitch screen ID |
|---|---|
| `01-pos-dashboard.{html,png}` — product grid, search + barcode, categories, dark cart + checkout | `2b933fa804fb435a9eb129f60b61ca4f` |
| `02-invoice.{html,png}` — logo, meta, items table, subtotal/tax/discount/total, QR, share + print | `525880adf564482494de4f045a5dbbfe` |
| `03-inventory.{html,png}` — search, chips, stock pills (ok / low / out), add-product FAB | `1c9755a29373495384ec3dda3340320f` |
| `04-reports.{html,png}` — today's sales hero KPI, invoice count, hourly bar chart, top 5 products | `f7f9d5a8e17a432db0d1da86300f42aa` |

HTML files are standalone Tailwind pages. Use them as a reference for the Flutter/web build.

## Notes
- Stitch's font list has no Cairo, so the design system uses Noto Sans. Cairo is set in the design notes and in every prompt, and all four HTML files load Cairo from Google Fonts.
- `download_assets` reported success but wrote nothing locally. The files here were fetched directly from the screen download URLs.
- Small fix for the build: the checkout button arrow on the POS screen points right. In RTL it should point left.
