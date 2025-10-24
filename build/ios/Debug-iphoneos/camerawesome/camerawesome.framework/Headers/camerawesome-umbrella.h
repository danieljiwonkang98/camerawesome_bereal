#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AnalysisController.h"
#import "AspectRatio.h"
#import "AspectRatioUtils.h"
#import "CameraDeviceInfo.h"
#import "CameraFlash.h"
#import "CameraPictureController.h"
#import "CameraPreviewTexture.h"
#import "CameraQualities.h"
#import "CameraSensor.h"
#import "CameraSensorType.h"
#import "CamerawesomePlugin.h"
#import "CaptureModes.h"
#import "CaptureModeUtils.h"
#import "ExifContainer.h"
#import "FlashModeUtils.h"
#import "ImageStreamController.h"
#import "InputAnalysisImageFormat.h"
#import "InputImageRotation.h"
#import "LocationController.h"
#import "MotionController.h"
#import "MultiCameraController.h"
#import "MultiCameraPreview.h"
#import "NSData+Exif.h"
#import "Permissions.h"
#import "PermissionsController.h"
#import "PhysicalButton.h"
#import "PhysicalButtonController.h"
#import "Pigeon.h"
#import "SensorsController.h"
#import "SensorUtils.h"
#import "SingleCameraPreview.h"
#import "VideoController.h"

FOUNDATION_EXPORT double camerawesomeVersionNumber;
FOUNDATION_EXPORT const unsigned char camerawesomeVersionString[];

