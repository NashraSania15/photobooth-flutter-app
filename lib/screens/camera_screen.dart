import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'preview_screen.dart';

enum PhotoFilter {
  none,
  grayscale,
  sepia,
  warm,
  cool,
  vintage,
  cinematic,
}

class CameraScreen extends StatefulWidget {
  final int stripCount;
  final int countdown;

  const CameraScreen({
    super.key,
    required this.stripCount,
    required this.countdown,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  int selectedCameraIndex = 0;

  final AudioPlayer tickPlayer = AudioPlayer();
  final AudioPlayer shutterPlayer = AudioPlayer();

  bool isCameraInitialized = false;
  bool isCounting = false;
  bool showFlash = false;

  int currentShot = 0;
  int countdownValue = 0;

  PhotoFilter selectedFilter = PhotoFilter.none;

  List<Map<String, dynamic>> capturedImages = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();

    selectedCameraIndex = cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    if (selectedCameraIndex == -1) {
      selectedCameraIndex = 0;
    }

    await _startCamera();
  }

  Future<void> _startCamera() async {
    _controller = CameraController(
      cameras[selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() => isCameraInitialized = true);
  }

  Future<void> switchCamera() async {
    selectedCameraIndex =
        (selectedCameraIndex + 1) % cameras.length;

    await _controller?.dispose();
    await _startCamera();
  }

  // ---------------- COUNTDOWN ----------------

  Future<void> startCountdownAndCapture() async {
    setState(() {
      isCounting = true;
      countdownValue = widget.countdown;
    });

    while (countdownValue > 0) {
      await tickPlayer.play(AssetSource('sounds/tick.mp3'));
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() => countdownValue--);
    }

    setState(() => isCounting = false);

    await captureImage();
  }

  // ---------------- CAPTURE ----------------

  Future<void> captureImage() async {
    if (!_controller!.value.isInitialized) return;

    await shutterPlayer.play(AssetSource('sounds/shutter.mp3'));

    final image = await _controller!.takePicture();
    final bytes = await image.readAsBytes();

    setState(() => showFlash = true);
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() => showFlash = false);

    capturedImages.add({
      "bytes": bytes,
      "filter": selectedFilter.name,
    });

    setState(() => currentShot++);

    if (!mounted) return;

    if (currentShot == widget.stripCount) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            images: List.from(capturedImages),
            stripCount: widget.stripCount,
            countdown: widget.countdown,
          ),
        ),
      );
    }
  }

  // ---------------- PREMIUM LIVE FILTER OVERLAY ----------------

  Widget buildFilterOverlay() {
    switch (selectedFilter) {
      case PhotoFilter.grayscale:
        return Container(color: Colors.grey.withOpacity(0.35));

      case PhotoFilter.sepia:
        return Container(color: const Color(0xFF704214).withOpacity(0.3));

      case PhotoFilter.warm:
        return Container(color: Colors.orange.withOpacity(0.2));

      case PhotoFilter.cool:
        return Container(color: Colors.blue.withOpacity(0.2));

      case PhotoFilter.vintage:
        return Container(color: const Color(0xFFCC9966).withOpacity(0.25));

      case PhotoFilter.cinematic:
        return Container(color: Colors.black.withOpacity(0.25));

      default:
        return const SizedBox();
    }
  }

  // ---------------- CAPTURE PROGRESS DOTS ----------------

  Widget buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.stripCount, (index) {
        bool isActive = index < currentShot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white24,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    tickPlayer.dispose();
    shutterPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCameraInitialized
          ? Stack(
        children: [

          Positioned.fill(
            child: CameraPreview(_controller!),
          ),


          Positioned.fill(child: buildFilterOverlay()),

          if (showFlash)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.85),
              ),
            ),

          if (isCounting)
            Center(
              child: Text(
                "$countdownValue",
                style: const TextStyle(
                  fontSize: 100,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: switchCamera,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    buildProgressDots(),

                    const SizedBox(height: 15),

                    SizedBox(
                      height: 45,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: PhotoFilter.values.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: ChoiceChip(
                              label: Text(
                                filter.name.toUpperCase(),
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: selectedFilter == filter,
                              selectedColor: Colors.white,
                              backgroundColor: Colors.black54,
                              labelStyle: TextStyle(
                                color: selectedFilter == filter
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  selectedFilter = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),
//transform
                    GestureDetector(
                      onTap: isCounting
                          ? null
                          : startCountdownAndCapture,
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: Colors.black,
                              width: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
