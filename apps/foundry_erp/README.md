# Foundry ERP

Production-ready ERPNext v15 / Frappe Framework app for foundry manufacturing:
**Tool Master** (Pattern / Core Box tooling register) and **Moulding Entry**
(one record per casting, with auto-generated Heat Codes and live Good/Bad/
Total counts).

---

## 1. Installation

Run these from your `frappe-bench` directory.

```bash
# 1. Get the app (copy this folder into apps/, or push it to your own git repo first)
bench get-app foundry_erp /path/to/foundry_erp

# 2. Install on your site
bench --site your-site-name install-app foundry_erp

# 3. Create the custom role used by permissions (also runs automatically
#    via after_install, this is only needed if you skipped that hook)
bench --site your-site-name execute foundry_erp.install.after_install

# 4. Migrate to sync DocTypes / Reports / Workspace / Page
bench --site your-site-name migrate

# 5. Build assets (bundles the standard app; the console's CSS is
#    self-injected at runtime so no separate CSS build step is required)
bench build --app foundry_erp

# 6. Restart
bench restart
```

### Assign the Moulding Operator role

```bash
bench --site your-site-name console
```
```python
import frappe
user = frappe.get_doc("User", "operator@yourcompany.com")
user.append("roles", {"role": "Moulding Operator"})
user.save()
frappe.db.commit()
```

Or via UI: **User List → select user → Roles → add "Moulding Operator"**.

---

## 2. What Gets Installed

| Component | Description |
|---|---|
| **Moulding Console** | Custom industrial HMI-style operator screen (Frappe Page, not the default form). Dark navy header, large touch targets, live Heat Code preview, single-Enter save, auto-refocus. |
| **Moulding Entry** | Transaction doctype. Every Save = one new casting record (never overwrites). Auto-fills Date, generates Heat Code live as the operator types the Heat Number, and computes Good/Bad/Total Count across all records sharing the same Heat Code. |
| **Tool Master** | Master doctype for Pattern/Core Box tooling. Cavity 1-8 fields show/hide automatically based on "No. of Cavities" via `depends_on`. `part_id` and `tool_id` are unique. |
| **Daily Production** | Script report: Good/Bad/Total qty + Rejection % grouped by date. |
| **Tool Wise Production** | Script report: same metrics grouped by Tool. |
| **Heat Wise Production** | Script report: same metrics grouped by Heat Code. |
| **Foundry ERP Workspace** | Desk workspace with shortcuts to both doctypes and all 3 reports. |
| **Moulding Operator role** | Auto-created on install. Can create Moulding Entry + read Tool Master; cannot edit/delete either. |

---

## 3. Moulding Console (Industrial Operator UI)

**URL:** `/app/moulding-console`

This is a hand-built Frappe Page (`foundry_erp/page/moulding_console/`) — it does **not** use the default ERPNext DocType form. It calls two lightweight whitelisted endpoints on the same `Moulding Entry` controller so there's a single source of truth for validation, Heat Code generation, and count logic:

- `moulding_entry.get_tool_options` — powers the Tool field (large text input + `<datalist>`, type-to-filter, keyboard navigable).
- `moulding_entry.create_entry` — thin wrapper around the normal `frappe.get_doc(...).insert()` call; permission-checked exactly like any other insert (no `ignore_permissions`).
- `moulding_entry.get_heat_code_preview` — same endpoint used for the instant Heat Code preview.

**Operator workflow (2-3 seconds per casting):**
1. Tool is selected once per session (auto-selected if only one Tool exists) and stays selected across saves.
2. Operator types the Heat Number → Heat Code appears instantly.
3. Result defaults to GOOD (segmented toggle, tap or click to flip to BAD — green/red highlight).
4. Press **Enter** in the Heat Number field (or tap the large Save button) → record saves, Good/Bad/Total stat cards update with a pulse animation, a toast confirms the Heat Code saved, and the Heat Number field clears and refocuses automatically for the next casting.

**Landing page:** the `Moulding Operator` role is routed straight to this console on login (`role_home_page` in `hooks.py`), skipping the standard Desk home/list view entirely. Administrators still have full access to the standard `Moulding Entry` list/form for corrections, audits, and bulk review — that default view was intentionally left in place for back-office use, only the shop-floor entry experience was replaced.

**Styling:** self-contained, injected via a single `<style>` block scoped under `.mc-wrap` in the page's JS (no external CSS file dependency, no `bench build` step required for styling to take effect — only `bench migrate` to register the Page).

---

## 4. Heat Code Logic

Format: `<YearCode><DayOfYear>-<HeatNumber>`

- **Year Code**: 2026 = G, 2027 = H, 2028 = I ... continues alphabetically.
- **Day of Year**: always 3 digits (001-366, leap years included).
- **Heat Number**: operator input, zero-padded to 3 digits.

Example: 01-Jan-2026, Heat Number 5 → **G001-005**

**Preview vs. persisted value:** The Heat Code appears the instant the
operator finishes typing the Heat Number (calls a whitelisted preview API
from `moulding_entry.js`). On **Save**, the server always recomputes the
Heat Code from scratch inside `validate()` and overwrites whatever the
browser sent — so the value shown to the operator and the value stored in
the database are generated by the exact same function
(`foundry_erp/utils/heat_code.py`) and can never disagree, and the field can
never be spoofed by tampering with the client.

> **Note on "Unique" Heat Code:** multiple Moulding Entry records intentionally
> **share** the same Heat Code (every casting poured from the same Heat Number
> on the same day) — this is required for the Good/Bad Count logic, which
> aggregates "records with the same Heat Code." "Unique" in the spec is
> interpreted as *uniquely identifying a batch*, not a DB-level unique
> constraint on the field. Flag this if a different interpretation was intended.

---

## 5. Good / Bad / Total Count Logic

On every Save:
1. The record's own counts are computed from all Moulding Entry rows
   sharing its Heat Code (via `frappe.db.count`).
2. Those same counts are then pushed to every **other** record sharing that
   Heat Code with a direct SQL `UPDATE` (bypasses controller hooks —
   fast, no recursive saves, safe at production volume).

All three fields are `read_only` in the DocType JSON and reinforced
read-only in the client script; they cannot be edited manually anywhere in
the UI.

---

## 6. Permissions Summary

| Role | Tool Master | Moulding Entry |
|---|---|---|
| Administrator / System Manager | Full CRUD | Full CRUD |
| Moulding Operator | Read only | Create + Read only (cannot edit/delete a saved entry — enforces "never overwrite") |

---

## 7. Known Assumptions (flag if incorrect)

1. **Tool Maker** is a free-text `Data` field, not a `Link` to Supplier — spec
   didn't specify a target doctype.
2. **"Good Quantity", "Bad Quantity", "Rejection %"** are implemented as
   **columns** inside the three grouped reports (Daily / Tool Wise / Heat
   Wise) rather than as three additional standalone reports, since the spec
   listed them directly under the same "Reports" heading as metrics, not as
   separate report names with their own grouping dimension.
3. **Moulding Entry autoname**: `ME-.YYYY.-.#####` (system-generated, not
   spec'd explicitly).
4. **Tool Master autoname**: `TM-.#####`, mirrored into the read-only
   "Auto ID" field per the spec's field list.
