import {describe, it, expect, beforeEach} from 'vitest';
import {publishDuePosts} from '../src/schedulePosts';

class FakeScheduledDoc {
  private _data: any;
  constructor(data: any) {
    this._data = data;
    this.ref = this;
  }
  ref: any;
  data() { return this._data; }
  async update(obj: any) { Object.assign(this._data, obj); }
}

class FakeUserDoc {
  id: string;
  scheduled: FakeScheduledDoc[];
  moderation: any[] = [];
  constructor(id: string, scheduled: any[]) {
    this.id = id;
    this.scheduled = scheduled.map(d => new FakeScheduledDoc(d));
  }
  collection(name: string) {
    if (name === 'scheduled') {
      const self = this;
      return {
        filters: [] as any[],
        where(field: string, op: string, value: any) {
          this.filters.push({field, op, value});
          return this;
        },
        async get() {
          let docs = self.scheduled;
          for (const f of this.filters) {
            if (f.field === 'publishAt' && f.op === '<=') {
              docs = docs.filter(d => d.data()[f.field] <= f.value);
            } else if (f.field === 'processedAt' && f.op === '==') {
              docs = docs.filter(d => d.data()[f.field] === f.value);
            }
          }
          return {docs};
        },
      };
    }
    if (name === 'moderation') {
      const arr = this.moderation;
      return {
        add: async (data: any) => { arr.push(data); },
      };
    }
    return {};
  }
}

class FakeFirestore {
  users: FakeUserDoc[] = [];
  posts: any[] = [];
  addUser(id: string, scheduled: any[]) {
    const u = new FakeUserDoc(id, scheduled);
    this.users.push(u);
    return u;
  }
  collection(path: string) {
    if (path.endsWith('/users')) {
      return {
        listDocuments: async () => this.users,
      };
    }
    if (path.endsWith('/posts')) {
      const arr = this.posts;
      return {
        add: async (data: any) => { arr.push(data); },
      };
    }
    return {};
  }
}

describe('publishDuePosts', () => {
  let db: FakeFirestore;
  const now = 0 as any;
  beforeEach(() => {
    db = new FakeFirestore();
  });

  it('publishes approved posts', async () => {
    const user = db.addUser('u1', [{publishAt: -1, processedAt: null, payload: {text: 'hi'}}]);
    await publishDuePosts(db as any, now);
    expect(db.posts.length).toBe(1);
    expect(user.moderation.length).toBe(0);
    expect(user.scheduled[0].data().processedAt).toBe(now);
  });

  it('stores rejected posts', async () => {
    const user = db.addUser('u1', [{publishAt: -1, processedAt: null, payload: {text: 'forbidden word'}}]);
    await publishDuePosts(db as any, now);
    expect(db.posts.length).toBe(0);
    expect(user.moderation.length).toBe(1);
    expect(user.scheduled[0].data().processedAt).toBe(now);
  });
});
