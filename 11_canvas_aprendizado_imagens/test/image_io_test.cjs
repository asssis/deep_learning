// Opcional: npm install --prefix tmp/js-test --no-save jsdom
// Executar da pasta 11: node --test test/image_io_test.cjs
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('../tmp/js-test/node_modules/jsdom');

function runtime() {
  const dom = new JSDOM('<!doctype html><html><body></body></html>', { runScripts: 'outside-only' });
  const window = dom.window;
  window.Blob = Blob;
  const created = [], revoked = [], downloads = [];
  window.URL.createObjectURL = blob => { created.push(blob); return `blob:test-${created.length}`; };
  window.URL.revokeObjectURL = url => revoked.push(url);
  window.HTMLAnchorElement.prototype.click = function () { downloads.push({ href: this.href, filename: this.download }); };
  window.setTimeout = callback => callback();
  window.eval(fs.readFileSync(path.join(__dirname, '../public/image_io.js'), 'utf8'));
  return { dom, io: window.SketchImageIO, created, revoked, downloads };
}

const triangle = '<svg xmlns="http://www.w3.org/2000/svg" width="260" height="260" viewBox="0 0 260 260"><title>triângulo</title><rect width="260" height="260" rx="20" fill="#f4f8ee"/><g fill="#cce7ac" stroke="#294b38" stroke-width="5" stroke-linejoin="round"><polygon points="130,40 220,210 40,210"/></g></svg>';

test('accepts the geometric SVG structure exported by example 10', async () => {
  const { dom, io } = runtime();
  try {
    const svg = io.safeSvg(triangle);
    assert.equal(svg.type, 'image/svg+xml');
    const text = await svg.text();
    assert.match(text, /polygon/);
    assert.match(text, /triângulo/);
    assert.equal(dom.window.document.querySelectorAll('svg').length, 0);
  } finally { dom.window.close(); }
});

test('rejects active SVG and external resources', () => {
  const { dom, io } = runtime();
  try {
    const wrap = body => `<svg xmlns="http://www.w3.org/2000/svg">${body}</svg>`;
    for (const svg of [wrap('<script>alert(1)</script>'), wrap('<foreignObject/>'), wrap('<style>@import "https://example.com/x.css";</style>'), wrap('<image href="https://example.com/x.png"/>'), wrap('<path fill="url(https://example.com/paint)"/>'), '<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"/>', '<!DOCTYPE svg><svg xmlns="http://www.w3.org/2000/svg"/>', '<svg']) {
      assert.throws(() => io.safeSvg(svg));
    }
  } finally { dom.window.close(); }
});

test('downloaded SVG can be validated for reimport and PNG export uses PNG', async () => {
  const { dom, io, created, downloads, revoked } = runtime();
  try {
    const png = 'data:image/png;base64,aGVsbG8=';
    const canvas = { width: 512, height: 512, toDataURL: () => png, toBlob: callback => callback(new Blob(['png'], { type: 'image/png' })) };
    await io.download(canvas, 'svg');
    assert.equal(downloads[0].filename, 'meu-desenho.svg');
    const text = await created[0].text();
    assert.match(text, /viewBox="0 0 512 512"/);
    assert.match(await io.safeSvg(text).text(), /href="data:image\/png;base64,/);
    await io.download(canvas, 'png');
    assert.equal(downloads[1].filename, 'meu-desenho.png');
    assert.equal(created[1].type, 'image/png');
    assert.equal(revoked.length, 2);
    assert.equal(dom.window.document.querySelectorAll('a').length, 0);
  } finally { dom.window.close(); }
});

test('validates file limits before opening and releases SVG resources after decode', async () => {
  const { dom, io, created, revoked } = runtime();
  try {
    await assert.rejects(io.load({ size: 6 * 1024 * 1024, name: 'x.svg', type: 'image/svg+xml' }), /5 MB/);
    await assert.rejects(io.load({ size: 10, name: 'x.txt', type: 'text/plain' }), /PNG, JPG, WebP ou SVG/);
    dom.window.Image = class {
      naturalWidth = 260;
      naturalHeight = 260;
      set src(value) { queueMicrotask(() => this.onload()); }
    };
    const image = await io.load({ size: triangle.length, name: 'triangulo.svg', type: 'image/svg+xml', text: async () => triangle });
    assert.equal(image.naturalWidth, 260);
    assert.equal(created[0].type, 'image/svg+xml');
    assert.equal(revoked.length, 1);
  } finally { dom.window.close(); }
});
