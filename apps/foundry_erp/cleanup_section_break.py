import frappe
frappe.init(site='foundry.local')
frappe.connect()

count = frappe.db.count('DocField', filters={'parent': 'Purchase Requisition Item', 'fieldname': 'section_break_main'})
print(f'section_break_main DocField count in DB: {count}')

meta = frappe.get_meta('Purchase Requisition Item')
print(f'Total fields in meta: {len(meta.fields)}')
has_sb = any(f.fieldname == 'section_break_main' for f in meta.fields)
print(f'Has section_break_main: {has_sb}')

if count > 0:
    frappe.db.delete('DocField', {'parent': 'Purchase Requisition Item', 'fieldname': 'section_break_main'})
    frappe.db.commit()
    print('Removed section_break_main from DB DocField')

frappe.destroy()
