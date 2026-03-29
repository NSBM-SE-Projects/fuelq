# FuelQ - Backend Setup Guide

## Firebase Services Required

- Firebase Authentication (Email/Password)
- Cloud Firestore

---

## 1. Firebase Authentication

### Enable Provider
Go to **Firebase Console → Authentication → Sign-in method** and enable:
- **Email/Password**

---

## 2. Firestore Database Structure

### Collection: `users`

| Field | Type | Description |
|-------|------|-------------|
| `uid` | string | Firebase Auth UID |
| `name` | string | Full name |
| `email` | string | Email address |
| `phone` | string | Phone number (e.g. +94 77 123 4567) |
| `nic` | string | National Identity Card number |
| `role` | string | One of: `vehicleOwner`, `stationAttendant`, `governmentAdmin` |
| `createdAt` | timestamp | Account creation time |

### Sub-collection: `users/{uid}/vehicles`

| Field | Type | Description |
|-------|------|-------------|
| `vehicleNumber` | string | Vehicle plate number (e.g. CAB-1234) |
| `chassisNumber` | string | Chassis number |
| `fuelType` | string | One of: `petrol`, `diesel` |
| `nickname` | string | Optional display name (e.g. Toyota Prius) |
| `createdAt` | timestamp | Vehicle registration time |

---

## 3. Firestore Security Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Users can only read/write their own vehicles
      match /vehicles/{vehicleId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## 4. Setup Steps

1. Go to [Firebase Console](https://console.firebase.google.com) → Select **fuelq-group12** project
2. **Authentication** → Sign-in method → Enable **Email/Password**
3. **Firestore Database** → Create database (Start in **test mode** for development, then apply rules above before production)
4. **Firestore** → Rules tab → Paste the security rules above → Publish

---

## 5. Test Data (Optional)

To manually test, create a user document in Firestore:

**Path:** `users/{any-uid}`
```json
{
  "uid": "test-user-001",
  "name": "Ashen Perera",
  "email": "ashen@example.com",
  "phone": "+94 77 123 4567",
  "nic": "987654321V",
  "role": "vehicleOwner",
  "createdAt": "2026-03-29T00:00:00Z"
}
```

**Path:** `users/{any-uid}/vehicles/{vehicle-id}`
```json
{
  "vehicleNumber": "CAB-1234",
  "chassisNumber": "JTDKN3DU5A0123456",
  "fuelType": "petrol",
  "nickname": "Toyota Prius",
  "createdAt": "2026-03-29T00:00:00Z"
}
```
