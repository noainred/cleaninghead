'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { IDBFactory } = require('fake-indexeddb');
const Babel = require('@babel/standalone');

const html = fs.readFileSync(path.join(__dirname, '../index.html'), 'utf8');
const source = html.split('<script type="text/babel" data-presets="env,react">')[1].split('</script>')[0];
const ast = Babel.packages.parser.parse(source, { sourceType: 'script', plugins: ['jsx'] });
const app = ast.program.body.find(n => n.type === 'FunctionDeclaration' && n.id.name === 'App');
const snippet = n => source.slice(n.start, n.end);
const globalFunction = name => snippet(ast.program.body.find(n => n.type === 'FunctionDeclaration' && n.id.name === name));
const appFunction = name => snippet(app.body.body.find(n => n.type === 'FunctionDeclaration' && n.id.name === name));

function storage() {
  const ctx = vm.createContext({ indexedDB: new IDBFactory(), console: { warn() {} }, structuredClone, setTimeout, Error });
  vm.runInContext(source.slice(source.indexOf("const DB_NAME ="), source.indexOf('/* ============================================================\n   ★ 구글 드라이브 연동 (drive.file')), ctx);
  return ctx;
}

function documentHarness() {
  const ctx = storage();
  const noop = () => {};
  const tree = { id: 'root-a', label: '문서 A', children: [], meta: {} };
  const ref = current => ({ current });
  Object.assign(ctx, {
    tree, inputText: '문서 A', currentDocId: 'a',
    currentDocIdRef: ref('a'), docListRef: ref([{ id: 'a', name: '문서 A', auto: true }]),
    docFoldersRef: ref([]), docTransitionRef: ref(false), localSaveSequenceRef: ref(0),
    lastLocalSaveRef: ref(null), syncSourceRef: ref(null), docFolderView: 'all',
    DEFAULT_DOC_NAME: '새 문서', DOC_KEY: id => 'doc:' + id,
    serializeTree: structuredClone, sanitizeTree: value => value && typeof value.label === 'string' ? structuredClone(value) : null,
    sanitizeTreeTruncated: () => false, treeToText: value => value.label,
    newDocId: () => 'new', genId: () => 'new-root', generateRootLabel: () => '새 아이디어', pickQuote: () => '',
    setDocList: noop, setCurrentDocId: id => { ctx.currentDocId = id; },
    setTree: value => { ctx.tree = value; }, setInputText: value => { ctx.inputText = value; },
    restoreWork: value => { ctx.tree = value.tree; ctx.inputText = value.inputText; },
    setLocalSaveStatus: value => { ctx.status = value; }, setDocBusy: value => { ctx.busy = value; },
    resetViewForDocChange: noop, setMorningQuote: noop, setShowDocs: noop, setRenamingDocId: noop,
    focusTextInputAtSecondLine: noop, showToast: message => { ctx.toast = message; },
  });
  vm.runInContext(['deriveDocName', 'docStatsOf', 'writeActiveDoc', 'currentDocPayload', 'flushActiveDoc', 'loadDocIntoView', 'switchDoc', 'createDoc', 'deleteDoc', 'duplicateDoc', 'importDocFromFile', 'importDriveFile'].map(appFunction).join('\n'), ctx);
  return ctx;
}

test('queued writes keep invocation order and reads wait for pending writes', async () => {
  const ctx = storage();
  const writes = Array.from({ length: 20 }, (_, i) => ctx.idbSet('value', i));
  assert.equal(await ctx.idbGet('value'), 19);
  assert.ok((await Promise.all(writes)).every(Boolean));
});

test('a failed multi-key transaction rolls back all writes and the queue recovers', async () => {
  const ctx = storage();
  await ctx.idbSetMany([['lastWork', 'original'], ['docMeta', 'a']]);
  assert.equal(await ctx.idbSetMany([['lastWork', 'corrupt'], ['docMeta', () => {}]]), false);
  assert.equal(await ctx.idbGet('lastWork'), 'original');
  assert.equal(await ctx.idbGet('docMeta'), 'a');
  assert.equal(await ctx.idbSet('next', 'success'), true);
});

test('abort without an error event settles as failure and closes the connection', async () => {
  const ctx = storage();
  let closed = false;
  ctx.openDB = async () => ({
    close: () => { closed = true; },
    transaction: () => {
      const tx = { objectStore: () => ({ put() {}, delete() {} }) };
      setTimeout(() => tx.onabort(), 0);
      return tx;
    },
  });
  assert.equal(await ctx.idbSet('x', 1), false);
  assert.equal(closed, true);
});

test('strict reads distinguish storage errors from a missing document', async () => {
  const ctx = storage();
  ctx.openDB = async () => { throw new Error('storage unavailable'); };
  assert.equal(await ctx.idbGet('missing'), undefined);
  await assert.rejects(ctx.idbGet('missing', { strict: true }), /storage unavailable/);
});

test('failed autosave does not mark the content saved and the same payload can retry', async () => {
  const ctx = documentHarness();
  const realWrite = ctx.idbSetMany;
  ctx.idbSetMany = async () => false;
  assert.equal(await ctx.flushActiveDoc(), false);
  assert.equal(ctx.status, 'error');
  assert.equal(ctx.lastLocalSaveRef.current, null);
  ctx.idbSetMany = realWrite;
  assert.equal(await ctx.flushActiveDoc(), true);
  assert.equal(ctx.status, 'saved');
  assert.equal((await ctx.idbGet('lastWork')).tree.label, '문서 A');
});

test('a delayed callback from another document cannot overwrite the active document', async () => {
  const ctx = documentHarness();
  assert.equal(await ctx.writeActiveDoc({ tree: ctx.tree, inputText: 'old' }, 'old-document'), false);
  assert.equal(await ctx.idbGet('lastWork'), undefined);
});

test('new document commits its slot, current pointer and restore mirror together', async () => {
  const ctx = documentHarness();
  await ctx.createDoc();
  const meta = await ctx.idbGet('docMeta');
  const mirror = await ctx.idbGet('lastWork');
  const slot = await ctx.idbGet('doc:new');
  assert.equal(meta.currentId, 'new');
  assert.deepEqual(mirror.tree, slot.tree);
  assert.equal((await ctx.idbGet('doc:a')).tree.label, '문서 A');
  assert.equal(ctx.tree.label, '새 아이디어');
});

test('new document creation does not switch or add a phantom card when storage fails', async () => {
  const ctx = documentHarness();
  const realWrite = ctx.idbSetMany;
  let writes = 0;
  ctx.idbSetMany = (...args) => ++writes === 2 ? Promise.resolve(false) : realWrite(...args);
  await ctx.createDoc();
  assert.equal(ctx.currentDocIdRef.current, 'a');
  assert.equal(ctx.docListRef.current.length, 1);
  assert.equal((await ctx.idbGet('lastWork')).tree.label, '문서 A');
  assert.equal(ctx.busy, false);
});

test('missing or corrupt documents leave the current document intact', async () => {
  const ctx = documentHarness();
  await ctx.switchDoc('missing');
  assert.equal(ctx.currentDocIdRef.current, 'a');
  assert.equal(ctx.tree.label, '문서 A');
  assert.match(ctx.toast, /문서를 읽지 못/);
});

test('rapid repeated switching is serialized and the final pointer matches the mirror', async () => {
  const ctx = documentHarness();
  ctx.docListRef.current.push({ id: 'b', name: '문서 B' });
  await ctx.idbSet('doc:b', { tree: { id: 'b-root', label: '문서 B', children: [] }, inputText: '문서 B' });
  await Promise.all([ctx.switchDoc('b'), ctx.switchDoc('a')]);
  assert.equal(ctx.currentDocIdRef.current, 'b');
  assert.equal((await ctx.idbGet('docMeta')).currentId, 'b');
  assert.equal((await ctx.idbGet('lastWork')).tree.label, '문서 B');
});

test('failed deletion of the active document preserves the document and pointer', async () => {
  const ctx = documentHarness();
  ctx.docListRef.current.push({ id: 'b', name: '문서 B' });
  await ctx.flushActiveDoc();
  await ctx.idbSet('doc:b', { tree: { id: 'b-root', label: '문서 B', children: [] }, inputText: '문서 B' });
  ctx.idbSetMany = async () => false;
  await ctx.deleteDoc('a');
  assert.equal(ctx.currentDocIdRef.current, 'a');
  assert.equal(ctx.docListRef.current.length, 2);
  assert.equal((await ctx.idbGet('doc:a')).tree.label, '문서 A');
});

test('deleting the active document atomically selects and mirrors its replacement', async () => {
  const ctx = documentHarness();
  ctx.docListRef.current.push({ id: 'b', name: '문서 B' });
  await ctx.flushActiveDoc();
  await ctx.idbSet('doc:b', { tree: { id: 'b-root', label: '문서 B', children: [] }, inputText: '문서 B' });
  await ctx.deleteDoc('a');
  assert.equal(await ctx.idbGet('doc:a'), undefined);
  assert.equal((await ctx.idbGet('docMeta')).currentId, 'b');
  assert.equal((await ctx.idbGet('lastWork')).tree.label, '문서 B');
});

test('flushing and duplicating before text debounce preserve the newest text and node metadata', async () => {
  const ctx = documentHarness();
  ctx.syncSourceRef.current = 'text'; ctx.inputText = '수정한 제목';
  ctx.tree.meta = { effort: 7 };
  Object.assign(ctx, {
    looksLikeBrainBloomMarkdown: () => false,
    parseInput: text => ({ id: 'parsed', label: text, children: [] }),
    walk: (tree, visit) => visit(tree),
    preserveMetadata: (parsed, old) => { parsed.meta = old.meta; },
    assignDefaultColors() {}, healDuplicateIds() {},
  });
  await ctx.flushActiveDoc();
  const saved = await ctx.idbGet('doc:a');
  assert.equal(saved.tree.label, '수정한 제목');
  assert.equal(saved.inputText, '수정한 제목');
  assert.equal(saved.tree.meta.effort, 7);
  await ctx.duplicateDoc('a');
  const copy = await ctx.idbGet('doc:new');
  assert.equal(copy.tree.label, '수정한 제목');
  assert.equal(copy.inputText, '수정한 제목');
  assert.equal(copy.tree.meta.effort, 7);
});

test('React nativeEvent IME Enter does not finish node editing or add a tag', () => {
  const ctx = vm.createContext({});
  vm.runInContext(globalFunction('isImeComposing'), ctx);
  const handlers = [];
  Babel.packages.traverse.default(ast, {
    VariableDeclarator(p) {
      if (p.node.id.name === 'handleKeyDown' && snippet(p.node).includes('cancelEdit')) handlers.push(p.node.init);
    },
    JSXAttribute(p) {
      if (p.node.name.name === 'onKeyDown' && snippet(p.node).includes('tagInput.trim')) handlers.push(p.node.value.expression);
    },
  });
  assert.equal(handlers.length, 2);
  let finished = 0;
  Object.assign(ctx, { finish: () => finished++, updateNode: () => finished++ });
  const event = { key: 'Enter', keyCode: 13, nativeEvent: { isComposing: true }, stopPropagation() {}, preventDefault() { finished++; } };
  for (const handler of handlers) vm.runInContext('(' + snippet(handler) + ')', ctx)(event);
  assert.equal(finished, 0);
  assert.equal(ctx.isImeComposing({ keyCode: 229 }), true);
  assert.equal(ctx.isImeComposing({ isComposing: true }), true);
  assert.equal(ctx.isImeComposing({ keyCode: 13 }), false);
});

test('a failed duplicate does not add a phantom document', async () => {
  const ctx = documentHarness();
  const realWrite = ctx.idbSetMany;
  let writes = 0;
  ctx.idbSetMany = (...args) => ++writes === 2 ? Promise.resolve(false) : realWrite(...args);
  await ctx.duplicateDoc('a');
  assert.equal(ctx.docListRef.current.length, 1);
  assert.equal(await ctx.idbGet('doc:new'), undefined);
  assert.match(ctx.toast, /사본을 저장하지 못/);
  assert.equal(ctx.busy, false);
});

test('JSON import reports storage failure without publishing an empty card', async () => {
  const ctx = documentHarness();
  let reading;
  Object.assign(ctx, {
    FileReader: class {
      readAsText() { this.result = JSON.stringify({ label: '가져온 문서', children: [] }); reading = this.onload(); }
    },
    walk: (tree, visit) => visit(tree), assignDefaultColors() {},
    setDocImportMsg: message => { ctx.importMessage = message; },
  });
  const realWrite = ctx.idbSetMany;
  let writes = 0;
  ctx.idbSetMany = (...args) => ++writes === 2 ? Promise.resolve(false) : realWrite(...args);
  ctx.importDocFromFile({}); await reading;
  assert.equal(ctx.docListRef.current.length, 1);
  assert.match(ctx.importMessage, /저장하지 못/);
  assert.equal(ctx.busy, false);
});

test('Drive import with open commits a new document and a consistent restore pointer', async () => {
  const ctx = documentHarness();
  Object.assign(ctx, {
    driveLoadFileById: async () => JSON.stringify({ tree: { label: '드라이브 문서', children: [] } }),
    walk: (tree, visit) => visit(tree), assignDefaultColors() {},
    setDriveImportingId() {}, setDriveImportedIds() {}, setDriveSignedIn() {},
  });
  await ctx.importDriveFile({ id: 'remote', name: 'backup.json' }, true);
  assert.equal(ctx.currentDocIdRef.current, 'new');
  assert.equal((await ctx.idbGet('lastWork')).tree.label, '드라이브 문서');
  assert.equal((await ctx.idbGet('docMeta')).currentId, 'new');
  assert.equal((await ctx.idbGet('doc:a')).tree.label, '문서 A');
});

test('toolbar keyboard activation is not intercepted by canvas shortcuts', () => {
  let handler;
  Babel.packages.traverse.default(ast, {
    VariableDeclarator(p) {
      if (p.node.id.name === 'handler' && snippet(p.node).includes("const inTextarea = e.target.tagName")) handler = p.node.init;
    },
  });
  assert.ok(handler);
  const ctx = vm.createContext(Object.fromEntries([
    'confirmNewFile', 'startupDialog', 'showSettings', 'showDocs', 'remoteNewer', 'colorCascade', 'showUpdate', 'welcomeQuote', 'calendarGeminiNotice',
  ].map(name => [name, false])));
  const run = vm.runInContext('(' + snippet(handler) + ')', ctx);
  // No canvas or navigator mocks: touching the canvas branch fails this test.
  for (const key of ['Enter', ' ', 'Tab', 'ArrowDown']) run({ key, target: { closest: () => ({ tagName: 'BUTTON' }) } });
});

test('service worker activation preserves caches owned by other apps', async () => {
  const handlers = {}, deleted = [];
  const ctx = vm.createContext({
    self: { addEventListener: (name, handler) => { handlers[name] = handler; }, clients: { claim: async () => {} } },
    caches: { keys: async () => ['bb-rt-v0', 'bb-rt-v1', 'other-app'], delete: async key => deleted.push(key) },
  });
  vm.runInContext(fs.readFileSync(path.join(__dirname, '../sw.js'), 'utf8'), ctx);
  let done;
  handlers.activate({ waitUntil: promise => { done = promise; } });
  await done;
  assert.deepEqual(deleted, ['bb-rt-v0']);
});
