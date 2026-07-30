import os
os.chdir('/home/sahil/frappe-bench/sites')
import frappe
frappe.init(site='foundry.local')
frappe.connect()

print('=== All Property Setters for Purchase Requisition Item ===')
ps_items = frappe.get_all('Property Setter',
    filters={'doc_type': 'Purchase Requisition Item'},
    fields=['name', 'field_name', 'property', 'value'])
for p in ps_items:
    print(f'  {p.name}: field={p.field_name}, property={p.property}, value={p.value}')
if not ps_items:
    print('  (none found)')

print()
print('=== All Property Setters for Purchase Requisition (parent) ===')
ps_parent = frappe.get_all('Property Setter',
    filters={'doc_type': 'Purchase Requisition'},
    fields=['name', 'field_name', 'property', 'value'])
for p in ps_parent:
    print(f'  {p.name}: field={p.field_name}, property={p.property}, value={p.value}')
if not ps_parent:
    print('  (none found)')

print()
print('=== DB field values for Purchase Requisition Item ===')
fields = frappe.get_all('DocField',
    filters={'parent': 'Purchase Requisition Item'},
    fields=['fieldname', 'fieldtype', 'in_list_view', 'hidden', 'depends_on', 'reqd'],
    order_by='idx')
for f in fields:
    print(f'  {f.fieldname:30s} {f.fieldtype:15s} in_list_view={f.in_list_view} hidden={f.hidden} reqd={f.get("reqd",0)} depends_on={f.get("depends_on") or ""}')

frappe.destroy()
