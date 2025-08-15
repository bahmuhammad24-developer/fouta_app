import {test} from 'node:test';
import assert from 'node:assert/strict';
import {checkSafetyRules} from '../src/safetyRules';

test('accepts valid content', () => {
  const res = checkSafetyRules({content: 'hello world', media: ['https://a']});
  assert.equal(res.ok, true);
});

test('rejects empty content', () => {
  const res = checkSafetyRules({content: ''});
  assert.equal(res.ok, false);
  assert.equal(res.reason, 'empty_content');
});

test('rejects too long content', () => {
  const long = 'a'.repeat(5001);
  const res = checkSafetyRules({content: long});
  assert.equal(res.ok, false);
  assert.equal(res.reason, 'content_too_long');
});

test('rejects insecure media', () => {
  const res = checkSafetyRules({content: 'ok', media: ['http://a']});
  assert.equal(res.ok, false);
  assert.equal(res.reason, 'insecure_media_url');
});

test('rejects forbidden words', () => {
  const res = checkSafetyRules({content: 'contains hateword1'});
  assert.equal(res.ok, false);
  assert.equal(res.reason, 'forbidden_terms');
});
