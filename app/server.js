const express = require('express');
const app = express();
app.use(express.json());

let locations = {}; // 메모리 저장소 (Firebase, DynamoDB로 확장 가능)

app.post('/update', (req, res) => {
  const { id, lat, lng } = req.body;
  if (!id || !lat || !lng) return res.status(400).send('Missing fields');
  locations[id] = { lat, lng, updatedAt: new Date() };
  res.sendStatus(200);
});

app.get('/location/:id', (req, res) => {
  const id = req.params.id;
  if (!locations[id]) return res.status(404).send('Not found');
  res.json(locations[id]);
});

const port = 3000;
app.listen(port, () => {
  console.log('Tracking app running on port ${port}');
});
