# FuelQ - QR Feature Backend Setup

## Firestore Collections

### Collection: `bookings`

> Each confirmed booking generates a QR code. This collection stores booking + QR data.

| Field | Type | Description |
|-------|------|-------------|
| `bookingId` | string | Auto-generated document ID |
| `userId` | string | Firebase Auth UID of the vehicle owner |
| `vehicleNumber` | string | Vehicle plate number (e.g. CAB-1234) |
| `vehicleId` | string | Reference to `users/{uid}/vehicles/{id}` |
| `stationId` | string | Fuel station ID |
| `stationName` | string | Fuel station display name |
| `fuelType` | string | `petrol` or `diesel` |
| `litresBooked` | number | Number of litres booked |
| `slotDate` | string | Booking date (e.g. `2026-03-29`) |
| `slotTime` | string | Time window (e.g. `09:00-10:00`) |
| `qrCode` | string | Encoded QR payload (JSON string with booking details) |
| `qrUsed` | boolean | `false` when generated, `true` after attendant scans |
| `scannedBy` | string | UID of the station attendant who scanned (null until scanned) |
| `scannedAt` | timestamp | When the QR was scanned (null until scanned) |
| `status` | string | `confirmed`, `completed`, `expired`, `cancelled` |
| `createdAt` | timestamp | Booking creation time |

---

## QR Code Payload Structure

The QR code encodes a JSON string with these fields:

```json
{
  "bookingId": "abc123",
  "vehicleNumber": "CAB-1234",
  "litres": 14,
  "fuelType": "petrol",
  "stationId": "station_54",
  "slotDate": "2026-03-29",
  "slotTime": "09:00-10:00",
  "userId": "firebase_uid_here"
}
```

---

## Firestore Security Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Existing user rules
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /vehicles/{vehicleId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Booking rules
    match /bookings/{bookingId} {
      // Vehicle owners can create and read their own bookings
      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid;

      allow read: if request.auth != null
                  && (resource.data.userId == request.auth.uid
                      || isStationAttendant());

      // Only station attendants can update qrUsed, scannedBy, scannedAt, status
      allow update: if request.auth != null
                    && isStationAttendant()
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['qrUsed', 'scannedBy', 'scannedAt', 'status']);
    }

    // Helper: check if user is a station attendant
    function isStationAttendant() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'stationAttendant';
    }
  }
}
```

---

## How It Works

### Vehicle Owner (QR Generation)
1. User creates a booking → document added to `bookings` collection
2. `qrCode` field is populated with encoded JSON payload
3. `qrUsed` is set to `false`, `status` is `confirmed`
4. App generates a QR image from the `qrCode` string using `qr_flutter`

### Station Attendant (QR Scanning)
1. Attendant opens scanner → uses `mobile_scanner` to read QR
2. App decodes the JSON payload → extracts `bookingId`
3. App reads `bookings/{bookingId}` from Firestore
4. Validates:
   - `qrUsed == false` (not already scanned)
   - `status == confirmed` (not cancelled/expired)
   - `stationId` matches the attendant's assigned station
   - `slotDate` matches today
5. On success → updates the document:
   - `qrUsed = true`
   - `scannedBy = attendant's UID`
   - `scannedAt = now`
   - `status = completed`

---

## Setup Steps

1. **Firestore** → Update security rules with the rules above
2. No additional Firebase services needed beyond what's already configured (Firestore + Auth)
