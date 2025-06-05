const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/api/hello', (req, res) => {
  res.json({
    message: 'Hello from the Backend!',
    source: 'Node.js/Express API',
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`Backend API listening at http://localhost:${port}`);
});