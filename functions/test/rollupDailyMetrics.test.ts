import {test} from 'node:test';
import assert from 'node:assert/strict';
import * as admin from 'firebase-admin';
import {countPaged} from '../src/rollupDailyMetrics';

const PROJECT = 'demo-rollup';

function init() {
  try {
    return admin.app();
  } catch {
    return admin.initializeApp({projectId: PROJECT}, `app-${Date.now()}`);
  }
}

test('counts >1000 documents from emulator', async (t) => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    t.skip('FIRESTORE_EMULATOR_HOST not set');
    return;
  }
  const app = init();
  const db = app.firestore();
  const col = db.collection('rollup-test');
  const writes: Promise<FirebaseFirestore.DocumentReference>[] = [];
  const now = new Date();
  for (let i = 0; i < 1100; i++) {
    writes.push(col.add({createdAt: now}));
  }
  await Promise.all(writes);
  const total = await countPaged(col.orderBy('createdAt'));
  assert.equal(total, 1100);
  await app.delete();
});
