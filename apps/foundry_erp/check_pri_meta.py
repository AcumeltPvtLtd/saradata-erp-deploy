import os
os.chdir('/home/sahil/frappe-bench/sites')
import frappe
frappe.init(site='foundry.local')
frappe.connect()

meta = frappe.get_meta('Purchase Requisition Item')
print('=== Purchase Requisition Item Meta ===')
print('editable_grid:', meta.editable_grid)
print()
for f in meta.fields:
    d = f.depends_on or ''
    m = f.mandatory_depends_on or ''
    print(f'  {f.fieldname:30s} {f.fieldtype:15s} hidden={f.hidden} in_list_view={f.in_list_view} depends_on={d} mandatory_depends_on={m}')

parent_meta = frappe.get_meta('Purchase Requisition')
for f in parent_meta.fields:
    if f.fieldtype == 'Table' and f.fieldname == 'items':
        print()
        print('Parent Table field editable_grid:', getattr(f, 'editable_grid', 'NOT SET'))

frappe.destroy()
