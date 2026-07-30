# FOUNDRY ERP — COMPLETE END-TO-END FUNCTIONAL AUDIT REPORT
**Date:** 27 July 2026  
**System:** Foundry ERP on Frappe v15  
**Site:** foundry.local  
**Modules:** Store (Purchase/GRN/QC/Stock), Melting, Moulding, Inventory  

---

## EXECUTIVE SUMMARY

This audit covers the complete business workflow from Item Master through Sales/Dispatch, examining 34+ DocTypes, 28+ reports, 3 custom roles, 17+ whitelisted APIs, and all production flows. The system shows strong foundational work in the Store module (PR→PO→GRN→QC flow) and Moulding console, but has **critical architectural defects** in the stock engine, production integration, and security layers that must be resolved before production deployment.

**Overall ERP Readiness Score: 38/100**

---

## 1. CRITICAL BUGS (Must fix before go-live)

### 1.1 Three DocTypes with Dead `on_submit`/`on_cancel` — Stock Never Moves
| DocType | Has on_submit? | Has is_submittable? | Result |
|---|---|---|---|
| **Store Stock Adjustment** | YES | **NO** | DEAD CODE — adjustments never affect stock |
| **Store Stock Transfer** | YES | **NO** | DEAD CODE — transfers never move stock |
| **Store Purchase Receipt** | YES | **NO** | DEAD CODE — QC's auto-PR fails on `.submit()` |

**Impact:** The Store Purchase Receipt is auto-created by QC on_submit via `pr.submit()`. If `is_submittable` is not set in the JSON, `pr.submit()` will throw "Document is not submittable", **breaking the entire QC→Stock flow**. Stock is never added.

**Fix:** Add `"is_submittable": 1` to all three DocType JSONs. Add `docstatus` field.

### 1.2 `reverse_ledger_for_voucher` Does NOT Recalculate Balances
**File:** `stock_engine.py`

After deleting ledger entries for a cancelled voucher, subsequent (still-existing) entries retain stale `balance_qty` and `balance_value`. Example: Entries A(bal=10), B(bal=8), C(bal=5). Cancel B → C still shows 5 but actual balance should be 10.

**Impact:** Any GRN/QC/Receipt cancellation corrupts the entire stock ledger chain from that point forward.

**Fix:** After deletion, recompute running balances for all remaining entries chronologically.

### 1.3 PR→PO Linkage is Completely Broken
- PR's "Create Purchase Order" button sends `linked_pr` field, but **PO has no `linked_pr` field defined**.
- PO Item's `pr_number` change handler in JS is **empty** (no-op).
- No server-side code auto-populates PO items from PR.
- **Impact:** The entire PR→PO workflow is non-functional. Users must manually create POs and manually add items.

### 1.4 `is_submittable` Missing from Store Purchase Receipt JSON
QC's `on_submit()` calls `pr.insert(); pr.submit()`. Without `is_submittable: 1`, `.submit()` crashes. **QC cannot complete.** Stock is never added via PR.

**Fix:** Add `"is_submittable": 1` and `"docstatus"` field to `store_purchase_receipt.json`.

### 1.5 No Server-Side Role Checks on Approval Functions
| Function | File | Role Check? |
|---|---|---|
| `approve_po()` | purchase_order.py | **NONE** |
| `reject_po()` | purchase_order.py | **NONE** |
| `close_po()` | purchase_order.py | **NONE** |
| `approve_grn()` | goods_receipt_note.py | **NONE** |
| `reject_grn()` | goods_receipt_note.py | **NONE** |

**Impact:** Any authenticated user (including Store Operators) can approve their own Purchase Orders and over-delivery GRNs. Complete bypass of separation of duties.

**Fix:** Add `if frappe.session.user not in get_admin_users(): frappe.throw("Not permitted")` to each function.

### 1.6 Melting Chemistry Schema/Code Mismatch
JSON defines: `item, ce, c_percent, si_percent`  
Python/JS/Reports reference: `actual, target, difference, status` — **fields that don't exist in the JSON**.

**Impact:** Chemistry validation is completely broken. Reports referencing these fields will throw SQL errors or return empty data.

### 1.7 Two Parallel, Disconnected Stock Systems
| Aspect | Inventory Module | Store Module |
|---|---|---|
| Ledger | Stock Ledger | Store Stock Ledger |
| Engine | stock_ledger.py | stock_engine.py |
| Submittable? | YES | NO |
| Valuation | Weighted average | Weighted average |

They never interact. Stock Adjustments/Transfers use Store module. Stock Ledger (Inventory) is only updated by its own hooks. **Inventory records don't reflect actual warehouse stock.**

---

## 2. HIGH SEVERITY ISSUES

### 2.1 Stock Engine: `frappe.db.commit()` Inside Functions
**File:** `stock_engine.py`

Every `stock_in()` and `stock_out()` call ends with `frappe.db.commit()`. This breaks Frappe's transactional model. If a later operation fails, earlier commits are already persisted and cannot be rolled back.

### 2.2 GRN Cancel Does NOT Reverse PO Quantities
`goods_receipt_note.py:92-95`: `on_cancel()` sets status to "Cancelled" but does **not** call `update_po_from_grn()`. The PO's `received_qty` and `pending_qty` remain permanently corrupted until the next GRN is submitted.

### 2.3 FIFO Engine is Completely Disconnected
- `fifo_enabled` on Items is never checked by any code
- `FIFO Layer` DocType exists but no transaction creates or consumes layers
- `fifo_engine.py` functions are never called from any transaction
- `Stock Ledger` has a `fifo_layer` link field but it's never populated
- Store Settings says "FIFO" but engine uses weighted average

### 2.4 Stock Transfer Hardcodes `rate=0`
When stock is transferred to destination warehouse, `stock_in()` is called with `rate=0`. This destroys the valuation of received stock. The original rate from the source warehouse should be preserved.

### 2.5 `current_stock_report` Shows Wildly Incorrect Values
The report `SUM(sl.balance_qty)` across ALL ledger entries instead of taking only the latest balance per item/warehouse. Any item with >1 ledger entry shows inflated stock.

### 2.6 `fifo_report` — Multiple Broken Filters
- `min_age`/`max_age` variables are computed but **never appended** to the SQL conditions
- `available_stock_only` filter variable is computed but **never used** in HAVING clause
- `consumed_qty` is hardcoded to 0 (data fetched but discarded)

### 2.7 No Negative Stock Prevention in Inventory Stock Ledger
`stock_ledger.py` — no check that `new_balance >= 0`. Stock Ledger happily creates negative balances.

### 2.8 Self-Approval Risk on Purchase Orders
A Store Operator can: create PO → submit PO (Pending Approval) → call `approve_po()` (no server-side role check) → PO is Approved. Complete bypass of the approval workflow.

---

## 3. MEDIUM SEVERITY ISSUES

### 3.1 Reports — Missing `docstatus` Filter (13 Reports)
All 10 Melting reports + all 3 Moulding reports lack `docstatus` filtering. Draft (unsubmitted) entries appear in production reports.

### 3.2 Reports — Missing Date Filters
`supplier_wise_purchase_orders`, `monthly_purchase_report`, `item_wise_purchase_orders`, `pending_purchase_orders` — all show ALL historical data with no date filter.

### 3.3 `pass_vs_fail_report` Shows Only DRAFT Entries
Unconditionally adds `AND docstatus = 0`. Should be `docstatus = 1`.

### 3.4 PR Approval Has No Audit Trail
PR approve/reject buttons use `frappe.client.set_value` directly — bypasses controller, creates no audit log, has no permission check.

### 3.5 PR Has No Close Mechanism
No close button, no close function. `Completed` status option exists but is unreachable. Partially-ordered PRs cannot be closed.

### 3.6 QC `rejected_qty` is Always 0
Field is `read_only=1` in JSON and never auto-calculated anywhere. `total_rejected_qty` summary always shows 0.

### 3.7 QC Rate Determination is Fragile
`frappe.db.get_value("Purchase Order Item", {"item_code": item.item_code}, "rate", order_by="creation desc")` fetches the most recently created PO item rate for ANY PO, not the specific PO linked to the GRN.

### 3.8 Dashboard Performance: 20+ Queries Per Load
`get_dashboard_data()` runs 20+ separate database queries including loading full stock_summary into Python just to count rows.

### 3.9 Race Conditions in Number Generation
All number generators (PR, PO, GRN, QC, SR) use query-then-insert pattern with no database locking. Concurrent creation can generate duplicate numbers (caught by unique constraint but produces ugly errors).

### 3.10 `custom_created_by`/`custom_created_on` Fields Never Populated
Every DocType has these 4 fields but no code ever sets them. They're always null. Redundant with Frappe's native `owner`/`creation`/`modified_by`/`modified`.

### 3.11 Store Settings — All Flags Are Decorative
`allow_negative_stock`, `stock_frozen_upto`, `default_valuation_method`, `auto_grn_on_delivery` — none are read by any code.

### 3.12 `supplier_wise_grn` Report — Inflated Counts
Uses per-row counting instead of `COUNT(DISTINCT ...)`. A GRN with 5 items counts as 5 pending_qc.

### 3.13 Two Parallel Item Registries
`Item Master` (Melting module, Select-based group) and `Items` (Inventory module, Link-based group) are separate, unrelated DocTypes. Melting Entry child tables reference `Items` (inventory), not `Item Master` (melting).

### 3.14 Stock Transfer — No Atomicity
If `stock_out()` succeeds but `stock_in()` fails, source warehouse loses stock but destination gains nothing. No transaction wrapping.

---

## 4. LOW SEVERITY ISSUES

| # | Issue | Location |
|---|---|---|
| 4.1 | `fifo_enabled` flag is dead — never read | Items |
| 4.2 | `is_group` field on Item Group is dead | Item Group |
| 4.3 | `weight_per_unit` validation contradiction (JSON allows 0, Python blocks it) | Items |
| 4.4 | `available_stock` and `reserved_stock` on Stock never populated | Stock DocType |
| 4.5 | `transaction_type` and `voucher_type` always identical (redundancy) | Store Stock Ledger |
| 4.6 | `item_name` never populated on Store Stock Ledger entries | Store Stock Ledger |
| 4.7 | `batch_no`/`serial_no` on FIFO Layer are plain Data, not Links | FIFO Layer |
| 4.8 | `reserved_qty` hardcoded to 0 in warehouse_wise_stock_report | Report |
| 4.9 | `stock_ledger_report` uses `SELECT *` and silent `LIMIT 500` | Report |
| 4.10 | Filter naming inconsistency (`date_from` vs `from_date`) | material_batch_report |
| 4.11 | `amount` field never computed on Stock Ledger | Stock Ledger |
| 4.12 | `total_amount` and `remaining_pending_qty` never populated on GRN Items | GRN Item |
| 4.13 | `Sent To Supplier` PO status is dead — never set | PO |
| 4.14 | `Completed` PR status is dead — never set | PR |
| 4.15 | 6 empty stub report directories | Store reports |

---

## 5. DATABASE / ARCHITECTURE ISSUES

### 5.1 No Composite Indexes
Store Stock Ledger queries use `(item_code, warehouse)` frequently but have no composite index. Performance degrades with data growth.

### 5.2 No Foreign Key Constraints
All Link fields are Frappe-managed. No database-level foreign keys. Deleting a referenced Item leaves orphaned records in PO Items, GRN Items, QC Items, etc.

### 5.3 No Audit Trail on QC and PR
QC and PR have no audit log child tables. Only Frappe's built-in `modified_by`/`modified` tracking exists. Status changes are not logged with who/when/why.

### 5.4 Valuation Never Decreases on Stock-Out
`stock_ledger.py` only updates `valuation_total` when `qty_change > 0`. Negative transactions don't reduce the total, making it permanently inflated.

### 5.5 Currency Fields Have No `options`
Store Stock Ledger's `balance_value` and `avg_rate` are Currency type but have no `options` set for currency. Symbol/format defaults to system settings.

---

## 6. MISSING ERP FEATURES

### 6.1 No Material Issue Document
Raw material consumption is recorded as data in Melting Material child rows but has **no inventory effect**. No Stock Ledger "Consumed" entries are created.

### 6.2 No Finished Goods Tracking
After Moulding, there is no record of what was produced in inventory terms. No "Produced" Stock Ledger entries.

### 6.3 No Production-to-Inventory Integration
Melting records raw materials but doesn't deduct from stock. Moulding records output but doesn't add to stock. The `Stock Ledger` transaction types include "Consumed" and "Produced" but nothing triggers them.

### 6.4 No Warehouse Management
No custom Warehouse DocType exists. All Warehouse links point to an external/unresolved DocType.

### 6.5 No Batch/Serial Number Tracking
FIFO Layer has `batch_no` and `serial_no` as plain Data fields. No Batch or Serial No DocType exists.

### 6.6 No Sales/Dispatch Module
The user's scenario includes Sales and Dispatch, but no DocTypes exist for either.

### 6.7 No Payment Reconciliation
`advance_paid` and `outstanding_amount` on PO are manual fields with no payment system integration.

### 6.8 No Multi-Currency Support
PO `currency` is optional and not validated against supplier's default currency.

---

## 7. SECURITY ISSUES

| # | Severity | Issue |
|---|---|---|
| 7.1 | **CRITICAL** | `approve_po`, `reject_po`, `approve_grn`, `reject_grn`, `close_po` — no server-side role check |
| 7.2 | **CRITICAL** | Store Operator can self-approve POs (create + submit + approve) |
| 7.3 | **HIGH** | Over-delivery approval functions callable by any user |
| 7.4 | **HIGH** | No "Approver" or "Purchase Manager" role exists |
| 7.5 | **MEDIUM** | PR approval uses client-side `frappe.client.set_value` — no server validation |
| 7.6 | **MEDIUM** | Dashboard data exposed to all roles without permission gating |
| 7.7 | **LOW** | `search_items` SQL uses `.format()` for WHERE clause (safe but should use parameterized approach) |

---

## 8. UI/UX PROBLEMS

| # | Issue |
|---|---|
| 8.1 | Store Stock Adjustment/Transfer have Submit buttons (from permissions) but on_submit never fires |
| 8.2 | `close_po` marks ALL items as "Completed" even those with 0 received_qty |
| 8.3 | QC `rejected_qty` field is read-only but there's no visual indication it should be auto-calculated |
| 8.4 | GRN `linked_po` is read-only but not required — can be blank even though items have PO references |
| 8.5 | Number format changed from GRN-NNNN to APL-GRN-YY-NNNNN mid-flight — existing docs have mixed formats |
| 8.6 | 6 empty report directories show in UI but have no implementation |

---

## 9. FOUNDRY-SPECIFIC MISSING FEATURES

| # | Feature | Status |
|---|---|---|
| 9.1 | Material Issue (store-to-production) | Missing |
| 9.2 | Finished Goods receipt | Missing |
| 9.3 | Production order / work order | Missing |
| 9.4 | Scrap tracking | Missing (melting FAIL records data but no stock effect) |
| 9.5 | Yield calculation (good parts / total) | Exists in Moulding (good_count/bad_count) but no inventory link |
| 9.6 | Heat-to-inventory traceability | Missing |
| 9.7 | Mould life tracking / preventive maintenance | Missing |
| 9.8 | Grade-wise stock tracking | Grade is on Melting Entry but not linked to inventory items |
| 9.9 | Production planning | Missing |
| 9.10 | BOM (Bill of Materials) | Missing |

---

## 10. RECOMMENDED IMPROVEMENTS (Priority Order)

### Phase 1: Critical Fixes (Must-Do Before Go-Live)
1. Add `is_submittable: 1` to Store Stock Adjustment, Store Stock Transfer, Store Purchase Receipt
2. Add server-side role checks to all approval/whitelisted functions
3. Fix `reverse_ledger_for_voucher` to recalculate balances after deletion
4. Fix `update_po_from_grn` to be called in GRN `on_cancel`
5. Fix Melting Chemistry JSON to include missing fields
6. Fix `current_stock_report` to show latest balance only
7. Fix QC `rejected_qty` auto-calculation (`inspected_qty - accepted_qty - partial_accepted_qty`)
8. Fix Store Stock Transfer to preserve rate from source warehouse
9. Fix PR→PO linkage (populate PO items from PR, or remove the broken button)

### Phase 2: High Priority
10. Remove `frappe.db.commit()` from stock_engine.py functions
11. Add negative stock prevention to Store Stock Ledger
12. Add audit trail child tables to QC and PR DocTypes
13. Fix all reports with missing `docstatus` filters (13 reports)
14. Fix FIFO report broken filters
15. Add date filters to reports missing them
16. Consolidate to single stock system (remove Inventory Stock Ledger or merge)

### Phase 3: Production Readiness
17. Add Material Issue document (store → production stock_out)
18. Add Finished Goods document (production → store stock_in)
19. Connect Melting/Moulding to stock engine
20. Add "Approver" role for PO/GRN approval separation
21. Add PR close mechanism
22. Add composite indexes on Store Stock Ledger
23. Implement number generation with database locking
24. Remove dead code (custom_created_by fields, decorative settings, dead statuses)

---

## 11. ERP READINESS SCORECARD

| Category | Weight | Score | Weighted |
|---|---|---|---|
| Core Purchase Flow (PR→PO→GRN→QC) | 20% | 45/100 | 9.0 |
| Stock Management | 20% | 25/100 | 5.0 |
| Production (Melting/Moulding) | 15% | 50/100 | 7.5 |
| Reports & Analytics | 15% | 35/100 | 5.25 |
| Security & Permissions | 15% | 20/100 | 3.0 |
| Data Integrity & Validations | 10% | 40/100 | 4.0 |
| UI/UX & Completeness | 5% | 45/100 | 2.25 |
| **TOTAL** | **100%** | | **36.0/100** |

### Verdict: **NOT READY FOR PRODUCTION**

The system requires **Phase 1 critical fixes** (9 items) before any production use. The stock engine, approval security, and QC→Stock flow are fundamentally broken. Once Phase 1 is complete, the system can handle basic purchase operations. Phases 2 and 3 are needed for a complete ERP.
