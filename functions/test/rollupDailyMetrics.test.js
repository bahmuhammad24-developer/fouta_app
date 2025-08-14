const assert = require('assert');
const Module = require('module');
const originalRequire = Module.prototype.require;
Module.prototype.require = function(request) {
  if (request === 'firebase-admin') {
    return {firestore: () => ({})};
  }
  if (request === 'firebase-functions/v2/scheduler') {
    return {onSchedule: () => () => {}};
  }
  return originalRequire.apply(this, arguments);
};
const {countPaged} = require('../lib/rollupDailyMetrics');

class MockQuery {
  constructor(data, start = 0, limitSize = Infinity) {
    this.data = data;
    this.start = start;
    this.limitSize = limitSize;
  }
  limit(n) {
    return new MockQuery(this.data, this.start, n);
  }
  startAfter(doc) {
    const index = this.data.indexOf(doc);
    return new MockQuery(this.data, index + 1, this.limitSize);
  }
  async get() {
    const slice = this.data.slice(this.start, this.start + this.limitSize);
    return {size: slice.length, docs: slice};
  }
}

(async () => {
  const docs = Array.from({length: 1200}, (_, i) => ({id: i}));
  const count = await countPaged(new MockQuery(docs), 500);
  assert.strictEqual(count, docs.length);
  console.log('countPaged test passed');
})();
