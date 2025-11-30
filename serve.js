/**
 * Simple HTTP Server for Fingrow App
 *
 * Usage: node serve.js
 * Then open: http://localhost:8000
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8000;

const mimeTypes = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
  console.log(`${req.method} ${req.url}`);

  // Default to index
  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './fingrow-app-mobile.html';
  }

  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = mimeTypes[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code == 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 - File Not Found</h1>', 'utf-8');
      } else {
        res.writeHead(500);
        res.end('Server Error: ' + error.code);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log('');
  console.log('🚀 Fingrow App Server Running!');
  console.log('');
  console.log('📱 Open in browser:');
  console.log(`   http://localhost:${PORT}`);
  console.log('');
  console.log('📄 Available pages:');
  console.log(`   http://localhost:${PORT}/fingrow-app-mobile.html        - Main App`);
  console.log(`   http://localhost:${PORT}/test-profile-mobile.html       - Profile Page`);
  console.log(`   http://localhost:${PORT}/test-profile.html              - Profile (Desktop)`);
  console.log('');
  console.log('Press Ctrl+C to stop');
  console.log('');
});
