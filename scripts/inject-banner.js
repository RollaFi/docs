// Idempotently add the staging banner to a Mintlify docs.json.
// Usage: node scripts/inject-banner.js docs.json
const fs = require('fs');

const file = process.argv[2] || 'docs.json';
const config = JSON.parse(fs.readFileSync(file, 'utf8'));

config.banner = {
  content:
    "🧪 You're viewing the **Staging** docs — base URL is `api-staging.rolla.xyz`. For production, see [docs.rolla.xyz](https://docs.rolla.xyz).",
  dismissible: true,
};

fs.writeFileSync(file, JSON.stringify(config, null, 2) + '\n');
console.log('✓ staging banner ensured in ' + file);
