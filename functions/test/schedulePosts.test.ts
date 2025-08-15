
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {publishDueScheduledPosts, schedulePosts} from '../src/schedulePosts';
import * as admin from 'firebase-admin';

function createStubs() {
  const posts: any[] = [];
  const moderation: any[] = [];
  const deletions: any[] = [];
  const userDoc = {
    id: 'user1',
    collection: (name: string) => ({
      where: () => ({
        get: async () => ({
          docs: [
            {
              id: 'sched1',
              data: () => ({
                payload: {content: 'hello', media: ['https://x'], visibility: 'public'},
                publishAt: new Date(),
              }),
              ref: {delete: async () => deletions.push(true)},
            },
          ],
        }),
      }),
    }),
  };
  const badUserDoc = {
    id: 'user1',
    collection: (name: string) => ({
      where: () => ({
        get: async () => ({
          docs: [
            {
              id: 'sched1',
              data: () => ({
                payload: {content: 'spam', media: ['https://x'], visibility: 'public'},
                publishAt: new Date(),
              }),
              ref: {delete: async () => deletions.push(true)},
            },
          ],
        }),
      }),
    }),
  };
  const db = {
    collection: (path: string) => {
      if (path.endsWith('/users')) {
        return {listDocuments: async () => [userDoc]};
      }
      if (path.endsWith('/posts')) {
        return {add: async (data: any) => posts.push(data)};
      }
      if (path.endsWith('/moderation/scheduled')) {
        return {
          doc: (id: string) => ({set: async (data: any) => moderation.push({id, ...data})}),
        };
      }
      return {listDocuments: async () => [badUserDoc]};
    },
  };
  return {db: db as any, posts, moderation, deletions};
}

test('publishes due posts', async () => {
  const {db, posts, moderation, deletions} = createStubs();
  const ts = {} as any; // timestamp not used in stub
  const original = admin.firestore.FieldValue.serverTimestamp;
  (admin.firestore.FieldValue as any).serverTimestamp = () => new Date();
  await publishDueScheduledPosts(db, ts);
  (admin.firestore.FieldValue as any).serverTimestamp = original;
  assert.equal(posts.length, 1);
  assert.equal(moderation.length, 0);
  assert.equal(deletions.length, 1);
});

test('rejects unsafe posts', async () => {
  const {db, posts, moderation, deletions} = createStubs();
  // replace users with bad payload
  (db.collection as any) = (path: string) => {
    if (path.endsWith('/users')) {
      return {
        listDocuments: async () => [
          {
            id: 'user1',
            collection: () => ({
              where: () => ({
                get: async () => ({
                  docs: [
                    {
                      id: 'sched1',
                      data: () => ({payload: {content: 'hateword1', media: ['https://x'], visibility: 'public'}}),
                      ref: {delete: async () => deletions.push(true)},
                    },
                  ],
                }),
              }),
            }),
          },
        ],
      };
    }
    if (path.endsWith('/posts')) return {add: async (data: any) => posts.push(data)};
    if (path.endsWith('/moderation/scheduled')) {
      return {doc: (id: string) => ({set: async (data: any) => moderation.push({id, ...data})})};
    }
    return {listDocuments: async () => []};
  };
  const ts = {} as any;
  const original = admin.firestore.FieldValue.serverTimestamp;
  (admin.firestore.FieldValue as any).serverTimestamp = () => new Date();
  await publishDueScheduledPosts(db, ts);
  (admin.firestore.FieldValue as any).serverTimestamp = original;
  assert.equal(posts.length, 0);
  assert.equal(moderation.length, 1);
  assert.equal(moderation[0].reason, 'forbidden_terms');
  assert.equal(moderation[0].createdBy, 'user1');
  assert.equal(deletions.length, 1);
});

test('flag off does nothing', async () => {
  process.env.SCHEDULED_POSTS_ENABLED = 'false';
  const {db, posts, moderation, deletions} = createStubs();
  const origFirestore = admin.firestore;
  (admin as any).firestore = () => db;
  await schedulePosts();
  (admin as any).firestore = origFirestore;
  assert.equal(posts.length, 0);
  assert.equal(moderation.length, 0);
  assert.equal(deletions.length, 0);

});
