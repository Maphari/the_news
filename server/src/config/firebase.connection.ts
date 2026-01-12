import admin from 'firebase-admin';
import serviceAccount from '../../firebase_service.json';
import dotenv from 'dotenv';

dotenv.config();

const FIREBASE_DB_URL: string = String(process.env.FIREBASE_DB_URL);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
  databaseURL: FIREBASE_DB_URL
});

const db = admin.firestore();
const auth = admin.auth();

export {db, admin, auth}