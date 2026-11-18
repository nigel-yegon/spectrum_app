// server.js (continuation of the M-Pesa server from earlier)
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const app = express();
const upload = multer({ dest: '/var/spectrum/backups/tmp/', limits: { fileSize: 50 * 1024 * 1024 } });

const API_KEY = process.env.SPECTRUM_API_KEY || 'change-me';
const BACKUP_DIR = '/var/spectrum/backups';

// Simple API key auth for backup endpoints
function requireApiKey(req, res, next) {
  if (req.header('X-API-Key') !== API_KEY) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
  next();
}

// POST /backup/upload
app.post(
  '/backup/upload',
  requireApiKey,
  upload.single('backup'),
  (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    // Optional: validate JSON shape
    try {
      const content = fs.readFileSync(req.file.path, 'utf8');
      const parsed = JSON.parse(content);
      if (!Array.isArray(parsed.properties)) {
        throw new Error('Missing "properties" array');
      }
    } catch (err) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'Invalid backup: ' + err.message });
    }

    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    const finalPath = path.join(BACKUP_DIR, `${stamp}.json`);
    fs.renameSync(req.file.path, finalPath);

    // Update the "latest" pointer via symlink
    const latestLink = path.join(BACKUP_DIR, 'latest.json');
    try { fs.unlinkSync(latestLink); } catch (_) {}
    fs.symlinkSync(finalPath, latestLink);

    // Cleanup: keep last 30
    const files = fs.readdirSync(BACKUP_DIR)
      .filter(f => /^\d{4}-/.test(f))
      .sort()
      .reverse();
    files.slice(30).forEach(f => fs.unlinkSync(path.join(BACKUP_DIR, f)));

    res.status(201).json({
      storedAt: new Date().toISOString(),
      sizeBytes: fs.statSync(finalPath).size,
    });
  }
);

// GET /backup/latest
app.get('/backup/latest', requireApiKey, (req, res) => {
  const latest = path.join(BACKUP_DIR, 'latest.json');
  if (!fs.existsSync(latest)) {
    return res.status(404).json({ error: 'No backup available' });
  }
  res.type('application/json').send(fs.readFileSync(latest, 'utf8'));
});

app.listen(3001, () => console.log('Spectrum server on :3001'));