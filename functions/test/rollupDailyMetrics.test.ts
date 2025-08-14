import {describe, it, expect} from 'vitest';
import {paginatedCount, PAGE_SIZE} from '../src/rollupDailyMetrics';

class FakeQuery {
  pages: any[][];
  index = 0;
  constructor(pages: any[][]) {
    this.pages = pages;
  }
  limit() { return this; }
  startAfter() { return this; }
  async get() {
    const docs = this.pages[this.index] || [];
    this.index++;
    return {size: docs.length, docs};
  }
}

describe('paginatedCount', () => {
  it('counts across multiple pages', async () => {
    const q = new FakeQuery([Array(PAGE_SIZE).fill({}), Array(5).fill({})]);
    const total = await paginatedCount(q as any);
    expect(total).toBe(PAGE_SIZE + 5);
  });
});
