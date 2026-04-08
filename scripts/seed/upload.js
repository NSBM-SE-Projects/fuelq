  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
  const db = admin.firestore();
  const auth = admin.auth();
  const seed = require('./seed_data.json');

  (async () => {
    // 1. Auth users
    for (const u of seed.users) {
      const pwdIndex = parseInt(u.email.match(/user(\d+)/)[1], 10);
      await auth.createUser({
        uid: u.uid, email: u.email, password: `Fuelq@${1000 + pwdIndex}`,
        displayName: u.name, phoneNumber: undefined,
      }).catch(() => {});
      console.log(`Auth: ${u.email}`);
    }

    // 2. User documents
    for (const u of seed.users) {
      const { _id, ...data } = u;
      data.createdAt = admin.firestore.Timestamp.fromDate(new Date(data.createdAt));
      await db.collection('users').doc(u.uid).set(data);
      console.log(`User: ${u.name}`);
    }

    // 3. Vehicles
    for (const v of seed.vehicles) {
      const { _id, _parentUserId, ...data } = v;
      ['weekStart', 'weekEnd', 'createdAt'].forEach(k => {
        data[k] = admin.firestore.Timestamp.fromDate(new Date(data[k]));
      });
      await db.collection('users').doc(_parentUserId).collection('vehicles').doc(_id).set(data);
      console.log(`Vehicle: ${data.vehicleNumber}`);
    }

    // 4. Stations
    for (const s of seed.stations) {
      const { _id, location, ...data } = s;
      data.location = new admin.firestore.GeoPoint(location.latitude, location.longitude);
      await db.collection('stations').doc(_id).set(data);
      console.log(`Station: ${data.name}`);
    }

    // 5. Bookings
    for (const b of seed.bookings) {
      const { _id, ...data } = b;
      ['slotStart', 'scannedAt', 'createdAt'].forEach(k => {
        if (data[k]) data[k] = admin.firestore.Timestamp.fromDate(new Date(data[k]));
      });
      await db.collection('bookings').doc(_id).set(data);
    }
    console.log(`Bookings: ${seed.bookings.length} created`);

    // 6. Config
    await db.collection('config').doc('booking').set(seed.config.booking);
    console.log('Config: done');

    console.log('Done.');
  })();