import app from './app';
import dotenv from 'dotenv';

//? Load environment variables from .env file
dotenv.config();

const PORT: number = Number(process.env.PORT);
const HOST: string = String(process.env.DEFAULT_PORT);

//? Start the server
app.listen(PORT, HOST, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📰 Environment: ${process.env.NODE_ENV || 'development'}`);
});