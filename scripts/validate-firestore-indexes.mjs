import fs from 'node:fs';

const FILE = 'firestore.indexes.json';
const raw = fs.readFileSync(FILE, 'utf8');
let json;
try {
  json = JSON.parse(raw);
} catch (e) {
  console.error(`\u274c ${FILE} is not valid JSON\n${e.message}`);
  process.exit(1);
}

const bads = [];
if (Array.isArray(json.indexes)) {
  json.indexes.forEach((idx, i) => {
    if (!Array.isArray(idx.fields)) return;
    idx.fields.forEach((f, j) => {
      if (!f || typeof f !== 'object') return;
      const hasOrder = Object.prototype.hasOwnProperty.call(f, 'order');
      const hasArrayConfig = Object.prototype.hasOwnProperty.call(f, 'arrayConfig');
      const hasVectorConfig = Object.prototype.hasOwnProperty.call(f, 'vectorConfig');
      const count = [hasOrder, hasArrayConfig, hasVectorConfig].filter(Boolean).length;
      if (count !== 1) {
        bads.push({
          index: i,
          fieldIndex: j,
          fieldPath: f.fieldPath ?? '(missing fieldPath)',
          keys: Object.keys(f)
        });
      }
    });
  });
}

if (bads.length) {
  console.error('\u274c Firestore indexes validation failed. Each field must have exactly one of "order", "arrayConfig", or "vectorConfig".');
  for (const b of bads) {
    console.error(` - indexes[${b.index}].fields[${b.fieldIndex}] fieldPath="${b.fieldPath}" keys=${JSON.stringify(b.keys)}`);
  }
  process.exit(1);
}

console.log('\u2705 Firestore indexes look good.');
process.exit(0);
