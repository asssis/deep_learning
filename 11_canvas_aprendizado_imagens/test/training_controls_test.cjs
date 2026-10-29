const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('../tmp/js-test/node_modules/jsdom');

function runtime() {
  const template = fs.readFileSync(path.join(__dirname, '../app/views/canvas/index.html.erb'), 'utf8');
  const html = template.replace(/<%[\s\S]*?%>/g, '');
  const dom = new JSDOM(`<meta name="csrf-token" content="test-token">${html}`, { runScripts: 'outside-only', url: 'http://localhost:3001' });
  const { window } = dom;
  window.HTMLCanvasElement.prototype.getContext = () => ({ fillRect() {} });
  window.confirm = () => true;
  const calls = [];
  let resolve;
  window.fetch = (url, options) => {
    calls.push({ url, options });
    return new Promise(done => { resolve = done; });
  };
  window.eval(fs.readFileSync(path.join(__dirname, '../public/canvas.js'), 'utf8'));
  return { dom, window, calls, reply(data, ok = true) { resolve({ ok, headers: { get: () => 'application/json' }, json: async () => data }); } };
}

const tick = () => new Promise(resolve => setImmediate(resolve));
const summary = (count, can_restore) => ({ count, can_restore, classes: count ? [{ label: 'estrela', count }] : [], examples: [] });

test('tabs switch panels by click and keyboard without replacing the canvas or making requests', () => {
  const app = runtime();
  try {
    const document = app.window.document;
    const canvas = document.getElementById('sketch');
    const learning = document.getElementById('learning-tab');
    const examples = document.getElementById('examples-tab');
    assert.equal(document.getElementById('learning-panel').hidden, false);
    assert.equal(document.getElementById('examples-panel').hidden, true);
    examples.click();
    assert.equal(document.getElementById('learning-panel').hidden, true);
    assert.equal(document.getElementById('examples-panel').hidden, false);
    assert.equal(document.getElementById('pretrain').closest('[role="tabpanel"]').id, 'examples-panel');
    assert.equal(document.getElementById('reset-training').closest('[role="tabpanel"]').id, 'examples-panel');
    assert.equal(examples.getAttribute('aria-selected'), 'true');
    assert.equal(learning.tabIndex, -1);
    examples.dispatchEvent(new app.window.KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }));
    assert.equal(document.getElementById('learning-panel').hidden, false);
    assert.equal(document.activeElement, learning);
    assert.equal(document.getElementById('sketch'), canvas);
    learning.dispatchEvent(new app.window.KeyboardEvent('keydown', { key: 'End', bubbles: true }));
    assert.equal(document.activeElement, examples);
    assert.equal(document.getElementById('examples-panel').hidden, false);
    assert.equal(app.calls.length, 0);
  } finally { app.dom.window.close(); }
});

test('pretrain and reset work without drawing and lock controls while pending', async () => {
  const app = runtime();
  try {
    const document = app.window.document;
    const pretrain = document.getElementById('pretrain');
    const reset = document.getElementById('reset-training');
    assert.equal(document.getElementById('identify').disabled, true);
    assert.equal(pretrain.disabled, false);
    assert.equal(document.querySelectorAll('.training-actions button').length, 2);
    assert.equal(document.querySelector('.starter-gallery'), null);
    pretrain.click();
    assert.equal(app.calls[0].url, '/treinamento/inicial');
    assert.equal(app.calls[0].options.headers['X-CSRF-Token'], 'test-token');
    assert.equal(reset.disabled, true);
    assert.equal(document.getElementById('training-progress').hidden, false);
    app.reply({ summary: summary(10, false), message: 'Base treinada.' });
    await tick();
    assert.equal(document.getElementById('sample-count').textContent, '10');
    assert.equal(pretrain.disabled, false);
    app.window.confirm = () => false;
    reset.click();
    assert.equal(app.calls.length, 1);
    app.window.confirm = () => true;
    reset.click();
    assert.equal(app.calls[1].url, '/treinamento/zerar');
    app.reply({ summary: summary(0, true), message: 'Aprendizado zerado.' });
    await tick();
    assert.equal(document.getElementById('sample-count').textContent, '0');
    assert.equal(document.getElementById('memory-empty').hidden, false);
    assert.equal(document.getElementById('training-state').textContent, 'Sem treinamento ativo');
  } finally { app.dom.window.close(); }
});

test('training errors keep the current notebook and release the controls', async () => {
  const app = runtime();
  try {
    const document = app.window.document;
    document.getElementById('pretrain').click();
    app.reply({ error: 'Não há espaço para a base inicial.' }, false);
    await tick();
    assert.equal(document.getElementById('feedback').hidden, false);
    assert.match(document.getElementById('feedback').textContent, /Não há espaço/);
    assert.equal(document.getElementById('pretrain').disabled, false);
    assert.equal(document.getElementById('identify').disabled, true);
  } finally { app.dom.window.close(); }
});
