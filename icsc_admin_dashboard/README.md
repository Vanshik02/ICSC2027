# ICSC 2027 Admin Dashboard

## 1. Install and run
```powershell
npm install
npm run dev
```
Open the local URL printed by Vite, usually `http://localhost:5173`.

## 2. Connect Firebase
Open `src/firebase.ts`. Replace every `PASTE_...` value with the configuration from:
Firebase Console → Project settings → General → Your apps → Web app.

If no Web app exists yet:
1. Click the Web icon (`</>`) under Your apps.
2. Register app name `ICSC 2027 Admin`.
3. Do not enable Firebase Hosting during registration.
4. Copy the Firebase configuration into `src/firebase.ts`.

## 3. Authentication
Use the same Email/Password administrator account already created in Firebase Authentication.
The dashboard checks `admins/{uid}` and requires `active: true`.

## 4. Firestore collections
The dashboard uses:
- `admins/{uid}`
- `conference_info/main`
- `announcements`
- `speakers`
- `sessions`

Published status is stored as `isPublished: true`. Announcements also receive `createdAt` as a Firestore timestamp.

## 5. Important
- Never put Firebase service-account credentials in this frontend.
- Firebase web config is intended to be included in client apps; security comes from Authentication and Firestore Security Rules.
- Add and test Firestore indexes only if Firebase reports that a query requires one.
- This initial dashboard manages text fields and links. Image uploads are intentionally not included because Firebase Storage may require upgrading the project plan.
