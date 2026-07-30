import os
os.chdir('/home/sahil/frappe-bench/sites')
import frappe
frappe.init(site='foundry.local')
frappe.connect()

meta = frappe.get_meta('Purchase Requisition Item')
print('Number of fields in meta:', len(meta.fields))

fields = frappe.get_meta('Purchase Requisition Item').fields
print('Fields from meta.fields:', len(fields))
for f in fields:
    print(f'  {f.fieldname}: ilv={f.get("in_list_view")} hidden={f.get("hidden")}')

frappe.destroy()
