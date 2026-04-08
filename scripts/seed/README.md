# FuelQ Seed Data

## What's in here

| File | Purpose |
|---|---|
| `generate.js` | Generator — run `node generate.js` to regenerate deterministic seed |
| `seed_data.json` | All seed data, ready to upload |
| `SEED_CREDENTIALS.md` | Every user's email + password (including the admin) |

## Contents

- **1** government admin (`user000@fuelq.test`)
- **100** vehicle owners spread across 6 regions
- **101** vehicles (one per user, ~70% petrol / ~30% diesel)
- **18** stations (3 per region: Colombo, Gampaha, Kandy, Galle, Matara, Jaffna)
- **~1,180** historical bookings over the last 30 days
- **1** `config/booking` document with pricing + slot settings

## How to upload (teammate)

The `seed_data.json` file is structured to match the Firestore schema exactly. Use a `firebase-admin` Node script like this:

```js
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
const db = admin.firestore();
const auth = admin.auth();
const seed = require('./seed_data.json');

(async () => {
  // 1. Auth users (passwords from SEED_CREDENTIALS.md — pattern: Fuelq@1XXX where XXX is user number)
  for (const u of seed.users) {
    const pwdIndex = parseInt(u.email.match(/user(\d+)/)[1], 10);
    await auth.createUser({
      uid: u.uid, email: u.email, password: `Fuelq@${1000 + pwdIndex}`,
      displayName: u.name, phoneNumber: undefined,
    }).catch(() => {});
  }

  // 2. users/{uid}
  for (const u of seed.users) {
    const { _id, ...data } = u;
    data.createdAt = admin.firestore.Timestamp.fromDate(new Date(data.createdAt));
    await db.collection('users').doc(u.uid).set(data);
  }

  // 3. users/{uid}/vehicles/{vid}
  for (const v of seed.vehicles) {
    const { _id, _parentUserId, ...data } = v;
    ['weekStart', 'weekEnd', 'createdAt'].forEach(k => {
      data[k] = admin.firestore.Timestamp.fromDate(new Date(data[k]));
    });
    await db.collection('users').doc(_parentUserId).collection('vehicles').doc(_id).set(data);
  }

  // 4. stations/{id}
  for (const s of seed.stations) {
    const { _id, location, ...data } = s;
    data.location = new admin.firestore.GeoPoint(location.latitude, location.longitude);
    await db.collection('stations').doc(_id).set(data);
  }

  // 5. bookings/{id}
  for (const b of seed.bookings) {
    const { _id, ...data } = b;
    ['slotStart', 'scannedAt', 'createdAt'].forEach(k => {
      if (data[k]) data[k] = admin.firestore.Timestamp.fromDate(new Date(data[k]));
    });
    await db.collection('bookings').doc(_id).set(data);
  }

  // 6. config/booking
  await db.collection('config').doc('booking').set(seed.config.booking);

  console.log('Done.');
})();
```

## Notes

- JSON stores timestamps as ISO strings — convert to `admin.firestore.Timestamp` on upload (see script above).
- Station `location` is stored as `{ latitude, longitude }` — convert to `GeoPoint` on upload.
- The generator uses a seeded RNG so re-running produces the **same** data. Change `_seed` in `generate.js` if you want a different set.
- Vehicle docs include a `_parentUserId` field — strip it before writing; it's just a pointer for the uploader script.
- Bookings include a `litres` field which is not in the original schema but is used by the analytics aggregations. Harmless to keep.
