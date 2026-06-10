const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

function runRestore(inputFile) {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    throw new Error('DATABASE_URL is not set in .env');
  }

  if (!fs.existsSync(inputFile)) {
    throw new Error(`Backup file not found: ${inputFile}`);
  }

  // Run pg_restore to restore database safely (clean drops old tables before creating them)
  const cmd = `pg_restore -d "${dbUrl}" --clean --if-exists --no-owner "${inputFile}"`;
  execSync(cmd, { stdio: 'pipe' });
}

if (require.main === module) {
  const inputFile = process.argv[2];
  if (!inputFile) {
    console.error('Please specify the backup file to restore.');
    process.exit(1);
  }
  try {
    console.log(`Starting restore from ${inputFile}...`);
    runRestore(inputFile);
    console.log('Restore completed successfully!');
  } catch (error) {
    console.error('Restore failed:', error.message);
    process.exit(1);
  }
}

module.exports = { runRestore };
