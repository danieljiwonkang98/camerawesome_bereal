# CameraAwesome Multi-Camera Preview Bug Fix

## Problem

When using multiple cameras with CameraAwesome, only the PiP (Picture-in-Picture) window showed the camera feed, but the main camera preview was black/not showing. Additionally, **front and back cameras were swapped in the PiP**. **This issue affected both Android and iOS platforms.**

## Root Cause

### Android Issues:

1. **Inconsistent Texture Key Mapping**: In `CameraAwesomeX.kt`, texture entries were being created using either `deviceId` or `index` as the key, but retrieval always used index as a string. This mismatch caused texture lookups to fail.

2. **Missing Surface Provider**: In concurrent camera mode, the surface provider was never set for the preview, so the camera had no surface to render to.

### iOS Issues:

1. **Wrong Index for Texture Updates**: In `MultiCameraPreview.m`, the `captureOutput` method was incrementing the index for every device in the loop, not breaking after finding the match. This caused the wrong texture to be updated with the camera feed.

2. **Sensor Index Not Tracked**: The `addSensor` method received an `index` parameter but didn't store it. Devices were appended to the array in whatever order they were added, not necessarily matching the sensor order. This caused front/back cameras to be swapped in PiP and photos.

## Fixes Applied

### Android Fixes

#### File: `android/src/main/kotlin/com/apparence/camerawesome/cameraX/CameraAwesomeX.kt`

**Line 149-151**: Changed texture entry key to always use index

```kotlin
// Before:
(pigeonSensor.deviceId ?: index.toString()) to textureRegistry!!.createSurfaceTexture()

// After:
// Always use index as key to match getPreviewTextureId lookup
index.toString() to textureRegistry!!.createSurfaceTexture()
```

#### File: `android/src/main/kotlin/com/apparence/camerawesome/cameraX/CameraXState.kt`

**Lines 140-143**: Added surface provider for concurrent cameras

```kotlin
// Set the surface provider for this preview using the index as key
preview.setSurfaceProvider(
    surfaceProvider(executor(activity), index.toString())
)
```

**Lines 215-218**: Updated single camera mode to use consistent key

```kotlin
// Before:
surfaceProvider(executor(activity), sensors.first().deviceId ?: "0")

// After:
// Use "0" as key for the first (and only) sensor in single camera mode
surfaceProvider(executor(activity), "0")
```

### iOS Fixes

#### File: `ios/camerawesome/Sources/camerawesome/include/CameraDeviceInfo.h`

**Line 15**: Added sensorIndex property to track which sensor each device corresponds to

```objc
@property (nonatomic, assign) int sensorIndex;  // Track which sensor this device corresponds to
```

#### File: `ios/camerawesome/Sources/camerawesome/CameraPreview/MultiCameraPreview/MultiCameraPreview.m`

**Line 297**: Store the sensor index when creating a device

```objc
cameraDevice.sensorIndex = index;  // Store the sensor index!
```

**Lines 380-393**: Fixed texture index matching in captureOutput

```objc
// Before (BUG):
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  int index = 0;
  for (CameraDeviceInfo *device in _devices) {
    if (device.videoDataOutput == output) {
      [_textures[index] updateBuffer:sampleBuffer];
      if (_onPreviewFrameAvailable) {
        _onPreviewFrameAvailable(@(index));
      }
    }
    index++; // BUG: Index kept incrementing even after match!
  }
}

// After (FIXED):
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  for (CameraDeviceInfo *device in _devices) {
    if (device.videoDataOutput == output) {
      // Found the matching device, use its stored sensor index to update the correct texture
      int sensorIndex = device.sensorIndex;
      [_textures[sensorIndex] updateBuffer:sampleBuffer];
      if (_onPreviewFrameAvailable) {
        _onPreviewFrameAvailable(@(sensorIndex));
      }
      // Break immediately after finding the match
      break;
    }
  }
}
```

**Lines 346-390**: Fixed photo capture to use correct device for each sensor

```objc
// Before (BUG):
for (int i = 0; i < [sensors count]; i++) {
  // ... setup ...
  [self.devices[i].capturePhotoOutput capturePhotoWithSettings:settings delegate:cameraPicture];
}

// After (FIXED):
for (int i = 0; i < [sensors count]; i++) {
  // Find the device that matches this sensor index
  CameraDeviceInfo *matchingDevice = nil;
  for (CameraDeviceInfo *device in _devices) {
    if (device.sensorIndex == i) {
      matchingDevice = device;
      break;
    }
  }
  // ... use matchingDevice instead of devices[i] ...
  [matchingDevice.capturePhotoOutput capturePhotoWithSettings:settings delegate:cameraPicture];
}
```

## Result

✅ **Android**: Main camera preview now displays correctly  
✅ **iOS**: Main camera preview now displays correctly  
✅ **iOS**: Front and back cameras no longer swapped in PiP  
✅ **iOS**: Correct camera captures each photo  
✅ PiP window shows the correct secondary camera on both platforms  
✅ Both cameras can capture photos simultaneously  
✅ All previews work consistently across single and multi-camera modes  
✅ Draggable PiP window with live camera feed

## Testing

Run the app on a physical device that supports multiple cameras (both Android and iOS):

```bash
# For iOS
flutter run -d <ios-device-id>

# For Android
flutter run -d <android-device-id>
```

You should now see:

- Main screen: Back camera live feed (full screen) ✅
- PiP window: Front camera live feed (draggable overlay) ✅
- Correct camera labels in PiP ✅
- Tap capture: Both cameras take a photo simultaneously ✅
- Tap thumbnail: View both photos in gallery ✅
- Photos are from the correct cameras (not swapped) ✅

## Local Installation

The modified CameraAwesome library is located in `./camerawesome_local` and is referenced in `pubspec.yaml`:

```yaml
camerawesome:
  path: ./camerawesome_local
```

## Files Modified

- ✅ `camerawesome_local/android/src/main/kotlin/com/apparence/camerawesome/cameraX/CameraAwesomeX.kt`
- ✅ `camerawesome_local/android/src/main/kotlin/com/apparence/camerawesome/cameraX/CameraXState.kt`
- ✅ `camerawesome_local/ios/camerawesome/Sources/camerawesome/include/CameraDeviceInfo.h` **(NEW)**
- ✅ `camerawesome_local/ios/camerawesome/Sources/camerawesome/CameraPreview/MultiCameraPreview/MultiCameraPreview.m`

## Key Insight

The core issue was **index mapping**: both platforms were not properly tracking which sensor index corresponded to which camera device/texture. By storing and using the sensor index explicitly, we ensure that:

- Sensor 0 (back camera) → always maps to texture/device 0
- Sensor 1 (front camera) → always maps to texture/device 1

This prevents cameras from being swapped regardless of the order devices are added or processed internally.
