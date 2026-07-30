const http = require('http');
const net = require('net');
const crypto = require('crypto');
const { execFile } = require('child_process');

const chrome = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const port = 9229;
const profile = 'C:\\Users\\aa\\AppData\\Local\\Temp\\foundry-grid-check-post-migrate';

function wait(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }
function getJson(path) {
  return new Promise((resolve, reject) => http.get({ hostname: '127.0.0.1', port, path }, res => {
    let body = ''; res.on('data', d => body += d); res.on('end', () => {
      try { resolve(JSON.parse(body)); } catch (e) { reject(new Error(body)); }
    });
  }).on('error', reject));
}
function frame(data) {
  const payload = Buffer.from(data); const mask = crypto.randomBytes(4); let header;
  if (payload.length < 126) header = Buffer.from([0x81, 0x80 | payload.length]);
  else { header = Buffer.alloc(4); header[0] = 0x81; header[1] = 0x80 | 126; header.writeUInt16BE(payload.length, 2); }
  for (let i = 0; i < payload.length; i++) payload[i] ^= mask[i % 4];
  return Buffer.concat([header, mask, payload]);
}
async function cdp(wsUrl) {
  const u = new URL(wsUrl); const key = crypto.randomBytes(16).toString('base64');
  const socket = net.connect(+u.port, u.hostname); let buffer = Buffer.alloc(0); let id = 0; const pending = new Map();
  await new Promise((resolve, reject) => {
    socket.once('connect', () => socket.write(`GET ${u.pathname} HTTP/1.1\r\nHost: ${u.host}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: ${key}\r\nSec-WebSocket-Version: 13\r\n\r\n`));
    socket.on('data', function handshake(d) {
      if (!/^HTTP\/1\.1 101\b/.test(d.toString())) return reject(new Error(d.toString()));
      socket.removeListener('data', handshake); socket.on('data', onData); resolve();
    }); socket.on('error', reject);
  });
  function onData(d) {
    buffer = Buffer.concat([buffer, d]);
    while (buffer.length >= 2) {
      let n = buffer[1] & 127, offset = 2;
      if (n === 126) { if (buffer.length < 4) return; n = buffer.readUInt16BE(2); offset = 4; }
      if (n === 127) { if (buffer.length < 10) return; n = Number(buffer.readBigUInt64BE(2)); offset = 10; }
      if (buffer.length < offset + n) return;
      const message = JSON.parse(buffer.subarray(offset, offset + n).toString()); buffer = buffer.subarray(offset + n);
      if (message.id && pending.has(message.id)) { pending.get(message.id)(message); pending.delete(message.id); }
    }
  }
  return {
    send(method, params = {}) { return new Promise(resolve => { const messageId = ++id; pending.set(messageId, resolve); socket.write(frame(JSON.stringify({ id: messageId, method, params }))); }); },
    close() { socket.end(); }
  };
}
async function main() {
  execFile(chrome, [`--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, '--no-first-run', '--no-default-browser-check', 'http://foundry.local:8000/login']);
  let pages; for (let i = 0; i < 30; i++) { try { pages = await getJson('/json/list'); break; } catch (_) { await wait(500); } }
  if (!pages) throw new Error('Chrome debugging endpoint did not start');
  const page = pages.find(p => p.type === 'page'); const client = await cdp(page.webSocketDebuggerUrl);
  const evalJs = async expression => {
    const response = await client.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (response.result?.exceptionDetails) throw new Error(response.result.exceptionDetails.exception?.description || response.result.exceptionDetails.text);
    return response.result?.result?.value;
  };
  await wait(1200);
  await evalJs(`(() => { const email = document.querySelector('#login_email'); const password = document.querySelector('#login_password'); if (email && password) { email.value='Administrator'; password.value='admin'; document.querySelector('.btn-login').click(); } })()`);
  for (let i = 0; i < 40; i++) { await wait(500); if ((await evalJs('location.pathname')).startsWith('/app')) break; }
  await client.send('Page.navigate', { url: 'http://foundry.local:8000/app/purchase-requisition/new' });
  for (let i = 0; i < 60; i++) { await wait(500); if (await evalJs(`window.cur_frm && cur_frm.doctype === 'Purchase Requisition'`)) break; }
  const ready = await evalJs(`!!(window.cur_frm && cur_frm.doctype === 'Purchase Requisition' && cur_frm.fields_dict.items)`);
  if (!ready) throw new Error('Purchase Requisition form did not load');
  await evalJs(`cur_frm.fields_dict.items.grid.wrapper.find('.grid-add-row').trigger('click')`);
  for (let i = 0; i < 20; i++) { await wait(250); if (await evalJs(`!!cur_frm.fields_dict.items.grid.open_grid_row`)) break; }
  const result = await evalJs(`JSON.stringify((() => { const grid = cur_frm.fields_dict.items.grid; const row = grid.open_grid_row; const form = row && row.grid_form; return { user: frappe.session.user, roles: frappe.user_roles, docstatus: cur_frm.doc.docstatus, is_new: cur_frm.is_new(), form_perm: cur_frm.perm, table_df: {read_only: grid.df.read_only, hidden: grid.df.hidden, permlevel: grid.df.permlevel}, is_editable: grid.is_editable(), grid_display_status: grid.display_status, allow_on_grid_editing: grid.allow_on_grid_editing(), rows: grid.grid_rows.length, has_open_row: !!row, has_grid_form: !!form, metadata: grid.docfields.map(f => ({fieldname:f.fieldname, hidden:f.hidden, depends_on:f.depends_on, permlevel:f.permlevel})), layout_fields: form ? form.layout.fields_list.filter(f => f.df).map(f => ({fieldname:f.df.fieldname, fieldtype:f.df.fieldtype, hidden:f.df.hidden, status:f.disp_status, class:f.$wrapper && f.$wrapper.attr('class')})) : [], visible_labels: form ? form.wrapper.find('.frappe-control:not(.hide-control) label').map((_,e) => e.textContent.trim()).get() : [], hidden_controls: form ? form.wrapper.find('.frappe-control.hide-control').map((_,e) => e.getAttribute('data-fieldname')).get() : [] }; })(), null, 2)`);
  if (result === undefined) throw new Error('Browser did not return the DOM inspection result');
  console.log(result);
  client.close();
}
main().catch(err => { console.error(err.stack || err); process.exit(1); });
