const db = require('./config/db');
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: "*" } });

io.on('connection', (socket) => {
  console.log('Client connected');
  socket.on('disconnect', () => console.log('Client disconnected'));
});

app.get('/', (req, res) => res.send('API Running'));

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));

const authRoutes = require('./routes/auth');
app.use('/auth', authRoutes);
