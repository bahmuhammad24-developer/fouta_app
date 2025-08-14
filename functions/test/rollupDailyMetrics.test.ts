import {test} from 'node:test';
import assert from 'node:assert/strict';
import {paginatedCount} from '../src/rollupDailyMetrics';

test('counts documents across pages', async () => {
  const pages = [[{}, {}], [{}, {}], [{}]];
  class StubQuery {
    constructor(private pages: any[][], private index = 0) {}
    orderBy() { return this; }
    limit() { return this; }
    async get() {
      return {size: this.pages[this.index].length, docs: this.pages[this.index]};
    }
    startAfter() { return new StubQuery(this.pages, this.index + 1); }
  }
  const total = await paginatedCount(new StubQuery(pages) as any, 2);
  assert.equal(total, 5);
});
