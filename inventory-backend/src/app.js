const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: '*' } });

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  socket.on('disconnect', () => console.log('Client disconnected:', socket.id));
});

app.get('/', (req, res) => res.send('API Running'));

const authRoutes = require('./routes/auth');
const inventoryRoutes = require('./routes/inventory');
const categoryRoutes = require('./routes/category');
const locationRoutes = require('./routes/location');

app.use('/auth', authRoutes);
app.use('/inventory', inventoryRoutes);
app.use('/categories', categoryRoutes);
app.use('/locations', locationRoutes);


// Make Socket.io accessible in routes
app.set('socketio', io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
