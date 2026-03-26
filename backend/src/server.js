const express = require('express');

const app = express();
const port = Number(process.env.API_PORT || 8080);

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'salefulbo-api',
    time: new Date().toISOString(),
  });
});

app.listen(port, () => {
  console.log(`salefulbo-api listening on port ${port}`);
});
