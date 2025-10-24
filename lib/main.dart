import 'dart:io';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'camerAwesome',
      home: CameraPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool? isMultiCamSupported;

  @override
  void initState() {
    super.initState();
    // Check if device supports multiple cameras
    CamerawesomePlugin.isMultiCamSupported().then((value) {
      setState(() {
        debugPrint("📸 isMultiCamSupported: $value");
        isMultiCamSupported = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (isMultiCamSupported == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: CameraAwesomeBuilder.awesome(
          saveConfig: SaveConfig.photoAndVideo(
            initialCaptureMode: CaptureMode.photo,
          ),
          sensorConfig: isMultiCamSupported == true
              ? SensorConfig.multiple(
                  sensors: [
                    Sensor.position(SensorPosition.back),

                    Sensor.position(SensorPosition.front),
                  ],
                  flashMode: FlashMode.auto,
                  aspectRatio: CameraAspectRatios.ratio_16_9,
                )
              : SensorConfig.single(
                  sensor: Sensor.position(SensorPosition.back),
                  flashMode: FlashMode.auto,
                  aspectRatio: CameraAspectRatios.ratio_16_9,
                ),
          enablePhysicalButton: true,
          previewFit: CameraPreviewFit.fitWidth,
          // This is the key! Picture-in-Picture configuration
          pictureInPictureConfigBuilder: isMultiCamSupported == true
              ? (index, sensor) {
                  debugPrint(
                    '🔍 PiP Builder called: index=$index, sensor.position=${sensor.position}',
                  );
                  return PictureInPictureConfig(
                    isDraggable: true,
                    startingPosition: Offset(
                      screenSize.width - 170,
                      screenSize.height - 420,
                    ),
                    sensor: sensor,
                    onTap: () {
                      debugPrint('Tapped on ${sensor.position} camera PiP');
                    },
                    pictureInPictureBuilder: (preview, aspectRatio) {
                      return Container(
                        width: 150,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // The actual camera preview!
                              Positioned.fill(child: preview),
                              // Label overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        sensor.position == SensorPosition.front
                                            ? Icons.camera_front
                                            : Icons.camera_rear,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        sensor.position == SensorPosition.front
                                            ? 'Front'
                                            : 'Back',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Drag indicator
                              Positioned(
                                top: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.drag_indicator,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              : null,
          onMediaTap: (mediaCapture) {
            // Handle media tap - show preview
            mediaCapture.captureRequest.when(
              single: (single) {
                final filePath = single.file?.path;
                if (filePath != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaPreviewPage(
                        filePath: filePath,
                        isVideo: mediaCapture.isPicture == false,
                      ),
                    ),
                  );
                }
              },
              multiple: (multiple) {
                final filePaths = multiple.fileBySensor.values
                    .where((file) => file?.path != null)
                    .map((file) => file!.path)
                    .toList();

                if (filePaths.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultipleMediaPreviewPage(
                        filePaths: filePaths,
                        isVideo: mediaCapture.isPicture == false,
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class MediaPreviewPage extends StatelessWidget {
  final String filePath;
  final bool isVideo;

  const MediaPreviewPage({
    super.key,
    required this.filePath,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isVideo ? 'Video Preview' : 'Photo Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved at: $filePath'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: isVideo
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library,
                    size: 100,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Video Preview',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      filePath,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 100,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading image\n$error',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class MultipleMediaPreviewPage extends StatefulWidget {
  final List<String> filePaths;
  final bool isVideo;

  const MultipleMediaPreviewPage({
    super.key,
    required this.filePaths,
    this.isVideo = false,
  });

  @override
  State<MultipleMediaPreviewPage> createState() =>
      _MultipleMediaPreviewPageState();
}

class _MultipleMediaPreviewPageState extends State<MultipleMediaPreviewPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.isVideo
              ? 'Videos (${_currentIndex + 1}/${widget.filePaths.length})'
              : 'Photos (${_currentIndex + 1}/${widget.filePaths.length})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved at: ${widget.filePaths[_currentIndex]}'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Image/Video viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.filePaths.length,
              itemBuilder: (context, index) {
                return Center(
                  child: widget.isVideo
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library,
                              size: 100,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Video ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )
                      : InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.file(
                            File(widget.filePaths[index]),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 100,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading image\n$error',
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                );
              },
            ),
          ),

          // Thumbnail strip at the bottom
          Container(
            height: 100,
            color: Colors.black87,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.filePaths.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.white24,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: widget.isVideo
                          ? const Center(
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white54,
                                size: 40,
                              ),
                            )
                          : Image.file(
                              File(widget.filePaths[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Camera labels
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.black87,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.filePaths.isNotEmpty)
                  const Column(
                    children: [
                      Icon(Icons.camera_front, color: Colors.white70, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Front Camera',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                if (widget.filePaths.length > 1)
                  const Column(
                    children: [
                      Icon(Icons.camera_rear, color: Colors.white70, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Back Camera',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
