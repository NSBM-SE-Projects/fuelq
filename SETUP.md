# FuelQ - Dev Setup Guide

## Prerequisites

Install these if you don't already have:

- [Flutter SDK](https://docs.flutter.dev/install/quick)
- [Android Studio](https://developer.android.com/studio)
- [VS Code](https://code.visualstudio.com)

## Step 1 -> Clone the repo

```bash
git clone https://github.com/NSBM-SE-Projects/fuelq.git
cd fuelq
```

Note: run each line of command seperately don't copy paste at once!

## Step 2 -> Download the secret files

Contact [dwainXDL](https://github.com/dwainXDL) for the shared Google Drive link, after the download:

Place:

- google-services.json -> fuelq -> android -> app -> *
- firebase_options.dart -> fuelq -> lib -> *

## Step 3 -> Run the setup script

Mac/Linux:
```bash
./setup.sh
```

Windows:
```bat
setup.bat
```

## Step 4 -> Run the app

```
flutter run
``` 

