import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import { handleSocketConnection } from './gateway/socket';

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Welcome to Foursquare Server');
});

const PORT = process.env.PORT || 3000;

io.on('connection', (socket) => {
    handleSocketConnection(io, socket);
});

server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
