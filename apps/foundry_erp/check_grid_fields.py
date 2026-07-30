import os
os.chdir('/home/sahil/frappe-bench/sites')
import frappe
frappe.init(site='foundry.local')
frappe.connect()

meta = frappe.get_meta('Purchase Requisition Item')
print('=== Server-side meta: all fields ===')
print([f.fieldname for f in meta.fields])

print()
print('=== Parent Table Field (items) ===')
pr_meta = frappe.get_meta('Purchase Requisition')
for f in pr_meta.fields:
    if f.fieldtype == 'Table' and f.fieldname == 'items':
        print('  options:', f.options)
        print('  editable_grid:', getattr(f, 'editable_grid', 'NOT SET'))
        break

frappe.destroy()
