const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

function runBackup(outputFile) {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    throw new Error('DATABASE_URL is not set in .env');
  }

  const backupDir = path.dirname(outputFile);
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  // Run pg_dump in custom binary format
  const cmd = `pg_dump -d "${dbUrl}" -F c -f "${outputFile}"`;
  execSync(cmd, { stdio: 'pipe' });
  return outputFile;
}

if (require.main === module) {
  const defaultFile = path.join(__dirname, '../backups', `backup-${Date.now()}.dump`);
  const outputFile = process.argv[2] || defaultFile;
  try {
    console.log(`Starting backup to ${outputFile}...`);
    runBackup(outputFile);
    console.log('Backup completed successfully!');
  } catch (error) {
    console.error('Backup failed:', error.message);
    process.exit(1);
  }
}

module.exports = { runBackup };
