SELECT name, grn_number, grand_total, status FROM `tabGoods Receipt Note` ORDER BY creation DESC LIMIT 3;
SELECT parent, item_code, rate, inward_qty, total_amount FROM `tabGoods Receipt Note Item` ORDER BY creation DESC LIMIT 5;
