# Debug Sensor Mapping Issue

## Problem

The PiP window label says "Front" but shows the back camera (or vice versa).

## Debug Logs Added

I've added comprehensive logging to track the sensor-to-camera mapping. Run your app on an iOS device and watch for these logs:

### 1. Flutter Side (in Dart console)

```
🔍 PiP Builder called: index=1, sensor.position=SensorPosition.front
```

This shows what sensor info Flutter thinks the PiP should display.

### 2. iOS - When Sensors Are Added

```
✅ Adding sensor at index 0, position: 1 (front=2, back=1), deviceID: ...
✅ Adding sensor at index 1, position: 2 (front=2, back=1), deviceID: ...
```

**What to check:**

- Index 0 should have position=1 (back camera)
- Index 1 should have position=2 (front camera)

**PigeonSensorPosition values:**

- `1` = Back
- `2` = Front

### 3. iOS - Device Selection

```
🔎 Checking device: Back Camera (position=1) against sensor.position=1 (looking for cameraType=1)
✅ MATCH! Selected device: Back Camera for sensor.position=1
```

**What to check:**

- Make sure "Back Camera" is selected for sensor.position=1
- Make sure "Front Camera" is selected for sensor.position=2

### 4. iOS - Frame Updates (every ~1 second)

```
📹 Updating texture[0] with frame 60 from device at position: 1
📹 Updating texture[1] with frame 60 from device at position: 2
```

**What to check:**

- texture[0] should be updated by position: 1 (back camera)
- texture[1] should be updated by position: 2 (front camera)

**AVCaptureDevicePosition values:**

- `1` = Front
- `2` = Back

## Expected Flow

1. **Flutter sends sensors in order:**

   - sensors[0] = Back (position=1 in Pigeon)
   - sensors[1] = Front (position=2 in Pigeon)

2. **iOS adds sensors:**

   - addSensor at index=0, sensor.position=1 (back) → device.sensorIndex=0
   - addSensor at index=1, sensor.position=2 (front) → device.sensorIndex=1

3. **iOS updates textures:**

   - Device with sensorIndex=0 updates texture[0] (back camera feed)
   - Device with sensorIndex=1 updates texture[1] (front camera feed)

4. **Flutter displays:**
   - texture[0] → Main view (labeled "Back")
   - texture[1] → PiP (labeled "Front")

## If Cameras Are Swapped

Look for these mismatches in logs:

### Possible Issue 1: Wrong device selected

```
❌ Adding sensor at index 0, position: 1, deviceID: <some-id>
📹 Updating texture[0] from device at position: 2  ← WRONG! Should be 1
```

**Fix:** Issue in `selectAvailableCamera` - selecting wrong device

### Possible Issue 2: Texture index mismatch

```
✅ Adding sensor at index 0, position: 1  ← Correct
📹 Updating texture[1] from device at position: 1  ← WRONG! Should update texture[0]
```

**Fix:** Issue with sensorIndex not being stored or used correctly

### Possible Issue 3: Sensor position values wrong

```
✅ Adding sensor at index 0, position: 2  ← WRONG! Should be 1 (back)
```

**Fix:** Issue in how Flutter is passing sensor positions to iOS

## How to Run

```bash
# In Xcode, run the app and watch the console
# Or from terminal:
flutter run -d <your-iphone-id>

# Then watch for the emoji logs in the output
```

## Next Steps

1. Run the app on your iPhone
2. Watch the Xcode console / terminal output
3. Copy the relevant logs (the ones with emojis)
4. Share them with me so we can identify exactly where the mismatch occurs
