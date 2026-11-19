import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

// Replace these placeholder values with the Firebase Web App configuration.
// Firebase Console > Project settings > General > Your apps > Web app.
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBjGTK6-WYYk-PCBUfHR4D5wD2Ai_YyN4Y",
  authDomain: "icsc-2027.firebaseapp.com",
  projectId: "icsc-2027",
  storageBucket: "icsc-2027.firebasestorage.app",
  messagingSenderId: "1073100272218",
  appId: "1:1073100272218:web:40f298114c23b41d5cde63",
  measurementId: "G-XQ25NRD2QG"
};

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)