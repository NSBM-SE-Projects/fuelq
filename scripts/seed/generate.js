#!/usr/bin/env node
/**
 * FuelQ seed data generator.
 *
 * Produces:
 *   - seed_data.json       (all collections, ready to import via firebase-admin)
 *   - SEED_CREDENTIALS.md  (all auth emails/passwords)
 *
 * Run: node generate.js
 *
 * The JSON matches the Firestore schema in the project. A teammate can upload
 * it using a firebase-admin script that iterates each collection in the file.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ---------- deterministic RNG so re-runs produce the same data ----------
let _seed = 42;
function rand() {
  _seed = (_seed * 9301 + 49297) % 233280;
  return _seed / 233280;
}
function randInt(min, max) { return Math.floor(rand() * (max - min + 1)) + min; }
function pick(arr) { return arr[Math.floor(rand() * arr.length)]; }

// ---------- helpers ----------
function uid() {
  // Firebase-style 28-char id
  return crypto.randomBytes(14).toString('hex').slice(0, 28);
}
function iso(d) { return d.toISOString(); }

// ---------- constants ----------
const REGIONS = [
  { name: 'Colombo',  weight: 30, lat: 6.9271, lng: 79.8612 },
  { name: 'Gampaha',  weight: 18, lat: 7.0873, lng: 79.9990 },
  { name: 'Kandy',    weight: 15, lat: 7.2906, lng: 80.6337 },
  { name: 'Galle',    weight: 12, lat: 6.0535, lng: 80.2210 },
  { name: 'Matara',   weight: 10, lat: 5.9485, lng: 80.5353 },
  { name: 'Jaffna',   weight: 15, lat: 9.6615, lng: 80.0255 },
];

const STATION_BRANDS = ['CPC', 'IOC', 'Lanka IOC', 'Ceypetco'];

const FIRST_NAMES = [
  'Nimal', 'Saman', 'Kasun', 'Ruwan', 'Tharindu', 'Ashen', 'Dilshan',
  'Chamara', 'Hashan', 'Lahiru', 'Pradeep', 'Sanjaya', 'Buddhika', 'Nuwan',
  'Roshan', 'Sunil', 'Mahinda', 'Chandana', 'Isuru', 'Amal', 'Tharaka',
  'Chaminda', 'Sachith', 'Dasun', 'Nalin', 'Kavindu', 'Gihan', 'Shehan',
  'Yasith', 'Tharindi', 'Nishani', 'Dilani', 'Ishara', 'Piumi', 'Sachini',
  'Nadeesha', 'Hiruni', 'Madushi', 'Thilini', 'Kumari',
];
const LAST_NAMES = [
  'Perera', 'Fernando', 'Silva', 'Jayasuriya', 'Bandara', 'Wickramasinghe',
  'Dissanayake', 'Rathnayake', 'Gunasekara', 'Senanayake', 'Weerasinghe',
  'Karunaratne', 'Abeysinghe', 'Rajapaksa', 'Edirisinghe', 'Pathirana',
  'Samaraweera', 'Liyanage', 'Mendis', 'de Silva',
];

const PETROL_VEHICLES = [
  { nick: 'Honda Civic',     chassisPrefix: 'JHMFB' },
  { nick: 'Toyota Prius',    chassisPrefix: 'JTDKN' },
  { nick: 'Suzuki Alto',     chassisPrefix: 'MA3FB' },
  { nick: 'Nissan March',    chassisPrefix: 'JN1AN' },
  { nick: 'Honda Fit',       chassisPrefix: 'JHMGE' },
  { nick: 'Bajaj Pulsar',    chassisPrefix: 'MD2DH' },
  { nick: 'Honda CB125',     chassisPrefix: 'MLHJC' },
  { nick: 'Yamaha FZ',       chassisPrefix: 'ME1RG' },
];
const DIESEL_VEHICLES = [
  { nick: 'Toyota Hiace',    chassisPrefix: 'JTFSS' },
  { nick: 'Isuzu Elf',       chassisPrefix: 'JALFR' },
  { nick: 'Mitsubishi L200', chassisPrefix: 'MMBJ' },
  { nick: 'Tata Dimo Batta', chassisPrefix: 'MAT45' },
  { nick: 'Toyota Hilux',    chassisPrefix: 'MR0FR' },
];

// ---------- users (100 + 1 admin) ----------
const users = [];
const credentials = [];

function makeUser(i, forceAdmin = false) {
  const first = pick(FIRST_NAMES);
  const last = pick(LAST_NAMES);
  const name = `${first} ${last}`;
  const email = `user${i.toString().padStart(3, '0')}@fuelq.test`;
  const password = `Fuelq@${1000 + i}`;
  const phone = `07${randInt(0, 9)}${randInt(1000000, 9999999)}`;
  const nic = `${randInt(1960, 2005)}${randInt(10000000, 99999999)}`;
  const userId = uid();
  const role = forceAdmin ? 'governmentAdmin' : 'vehicleOwner';

  // Weighted region pick
  const totalW = REGIONS.reduce((s, r) => s + r.weight, 0);
  let r = rand() * totalW;
  let region = REGIONS[0];
  for (const reg of REGIONS) {
    r -= reg.weight;
    if (r <= 0) { region = reg; break; }
  }

  users.push({
    _id: userId,
    uid: userId,
    name,
    email,
    phone,
    nic,
    role,
    region: region.name, // not in schema but harmless; remove if you prefer strict
    createdAt: iso(new Date(Date.now() - randInt(1, 120) * 86400000)),
  });

  credentials.push({ i, name, email, password, role, region: region.name });

  return { userId, region };
}

// Admin first
const admin = makeUser(0, true);

// 100 regular users
const userMeta = [admin];
for (let i = 1; i <= 100; i++) {
  userMeta.push(makeUser(i, false));
}

// ---------- vehicles (1 per user, admin included) ----------
const vehicles = [];
function plateFor(region, idx) {
  const letters = ['CAB', 'CAC', 'CBA', 'WP', 'CP', 'GA', 'NB', 'KU', 'NW', 'JA'];
  return `${pick(letters)}-${randInt(1000, 9999)}`;
}

userMeta.forEach((u, idx) => {
  const isPetrol = rand() < 0.7;
  const spec = pick(isPetrol ? PETROL_VEHICLES : DIESEL_VEHICLES);
  const vehicleId = uid();
  const weeklyLimit = isPetrol ? 16.0 : 32.0;
  const used = +(rand() * weeklyLimit).toFixed(2);
  const now = Date.now();
  const weekStart = new Date(now - (new Date().getDay() * 86400000));
  const weekEnd = new Date(weekStart.getTime() + 7 * 86400000);
  vehicles.push({
    _parentUserId: u.userId,
    _id: vehicleId,
    vehicleNumber: plateFor(u.region, idx),
    chassisNumber: `${spec.chassisPrefix}${randInt(100000, 999999)}`,
    fuelType: isPetrol ? 'petrol' : 'diesel',
    nickname: spec.nick,
    used,
    weeklyLimit,
    weekStart: iso(weekStart),
    weekEnd: iso(weekEnd),
    createdAt: iso(new Date(now - randInt(1, 120) * 86400000)),
  });
});

// ---------- stations (3 per region = 18) ----------
const stations = [];
REGIONS.forEach((region) => {
  for (let s = 1; s <= 3; s++) {
    const brand = pick(STATION_BRANDS);
    const id = uid();
    stations.push({
      _id: id,
      name: `${brand} Fuel Station - ${region.name} ${s}`,
      address: `No. ${randInt(1, 300)}, ${region.name} Main Road, ${region.name}`,
      region: region.name,
      location: {
        latitude: +(region.lat + (rand() - 0.5) * 0.15).toFixed(6),
        longitude: +(region.lng + (rand() - 0.5) * 0.15).toFixed(6),
      },
      fuelTypes: ['petrol92', 'petrol95', 'diesel'],
      availability: pick(['available', 'available', 'busy', 'full']),
      currentQueue: randInt(0, 45),
      maxQueue: 50,
      openTime: '06:00',
      closeTime: '22:00',
      isOpen: true,
    });
  }
});

// ---------- bookings (last 30 days, ~3/user/week) ----------
const bookings = [];
const statuses = ['completed', 'completed', 'completed', 'completed', 'cancelled', 'noShow'];
const paymentMethods = ['card', 'cash'];

vehicles.forEach((veh) => {
  if (veh._parentUserId === admin.userId) return; // admin has no bookings
  const user = userMeta.find((u) => u.userId === veh._parentUserId);
  // ~12 bookings over 30 days (roughly 3/week)
  const count = randInt(8, 15);
  for (let b = 0; b < count; b++) {
    const daysAgo = randInt(0, 30);
    const hour = randInt(6, 20);
    const slotStart = new Date(Date.now() - daysAgo * 86400000);
    slotStart.setHours(hour, randInt(0, 1) * 30, 0, 0);

    // Pick a station in the user's region (or any if none)
    const regionStations = stations.filter((s) => s.region === user.region);
    const station = pick(regionStations.length ? regionStations : stations);

    const litres = veh.fuelType === 'petrol' ? randInt(3, 16) : randInt(5, 32);
    const price = veh.fuelType === 'petrol' ? 366 : 336;
    const status = pick(statuses);
    const payment = pick(paymentMethods);

    bookings.push({
      _id: uid(),
      userId: user.userId,
      stationId: station._id,
      stationName: station.name,
      vehicleId: veh._id,
      vehicleNumber: veh.vehicleNumber,
      fuelType: veh.fuelType,
      litres, // not in original schema but useful for analytics
      slotStart: iso(slotStart),
      status,
      qrToken: crypto.randomUUID(),
      qrUsed: status === 'completed',
      scannedBy: status === 'completed' ? 'seed-attendant' : null,
      scannedAt: status === 'completed' ? iso(slotStart) : null,
      paymentMethod: payment,
      paymentStatus: status === 'completed' ? 'paid' : 'pending',
      amount: +(litres * price).toFixed(2),
      cardLast4: payment === 'card' ? `${randInt(1000, 9999)}` : null,
      createdAt: iso(new Date(slotStart.getTime() - randInt(1, 48) * 3600000)),
    });
  }
});

// ---------- config ----------
const config = {
  booking: {
    slotDurationMinutes: 30,
    maxVehiclesPerSlot: 15,
    cancelWindowMinutes: 30,
    arrivalWindowMinutes: 15,
    maxBookingsPerVehiclePerDay: 1,
    petrolPricePerLiter: 366,
    dieselPricePerLiter: 336,
  },
};

// ---------- write outputs ----------
const out = {
  users,
  vehicles,     // each has _parentUserId — upload under users/{parent}/vehicles/{_id}
  stations,
  bookings,
  config,
  _meta: {
    generatedAt: new Date().toISOString(),
    counts: {
      users: users.length,
      vehicles: vehicles.length,
      stations: stations.length,
      bookings: bookings.length,
    },
  },
};

const outDir = __dirname;
fs.writeFileSync(path.join(outDir, 'seed_data.json'), JSON.stringify(out, null, 2));

// Credentials markdown
let md = `# FuelQ Seed Credentials\n\n`;
md += `Generated: ${new Date().toISOString()}\n\n`;
md += `All passwords follow the pattern \`Fuelq@1XXX\`.\n\n`;
md += `## Government Admin\n\n`;
const adminCred = credentials.find((c) => c.role === 'governmentAdmin');
md += `| Email | Password | Name |\n|---|---|---|\n`;
md += `| \`${adminCred.email}\` | \`${adminCred.password}\` | ${adminCred.name} |\n\n`;
md += `## Vehicle Owners (100)\n\n`;
md += `| # | Name | Region | Email | Password |\n|---|---|---|---|---|\n`;
credentials
  .filter((c) => c.role !== 'governmentAdmin')
  .forEach((c) => {
    md += `| ${c.i} | ${c.name} | ${c.region} | \`${c.email}\` | \`${c.password}\` |\n`;
  });
fs.writeFileSync(path.join(outDir, 'SEED_CREDENTIALS.md'), md);

console.log(`Seed generated:`);
console.log(`  users     : ${users.length}`);
console.log(`  vehicles  : ${vehicles.length}`);
console.log(`  stations  : ${stations.length}`);
console.log(`  bookings  : ${bookings.length}`);
console.log(`\nFiles:`);
console.log(`  ${path.join(outDir, 'seed_data.json')}`);
console.log(`  ${path.join(outDir, 'SEED_CREDENTIALS.md')}`);
