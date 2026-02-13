import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'camera_screen.dart';

enum StripLayout { vertical, grid, triple }
enum FrameStyle { classic, dark, retro, neon }

class PreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int stripCount;
  final int countdown;

  const PreviewScreen({
    super.key,
    required this.images,
    required this.stripCount,
    required this.countdown,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? finalStrip;

  StripLayout selectedLayout = StripLayout.vertical;
  FrameStyle selectedFrame = FrameStyle.classic;

  @override
  void initState() {
    super.initState();
    generateStripAsync();
  }

  Future<void> generateStripAsync() async {
    setState(() => finalStrip = null);

    final result = await compute(generateStripIsolate, {
      "images": widget.images,
      "layout": selectedLayout.name,
      "frame": selectedFrame.name,
    });

    if (!mounted) return;
    setState(() => finalStrip = result);
  }

  Future<String> saveTempFile() async {
    final directory = await getTemporaryDirectory();
    final filePath =
        "${directory.path}/photobooth_${DateTime.now().millisecondsSinceEpoch}.png";
    final file = File(filePath);
    await file.writeAsBytes(finalStrip!);
    return filePath;
  }

  Future<void> downloadImage() async {
    await Permission.photos.request();
    await Permission.storage.request();

    final path = await saveTempFile();
    await GallerySaver.saveImage(path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved to Gallery")),
    );
  }

  Future<void> shareImage() async {
    final path = await saveTempFile();
    await Share.shareXFiles([XFile(path)]);
  }

  Color getFrameColor() {
    switch (selectedFrame) {
      case FrameStyle.dark:
        return Colors.black;
      case FrameStyle.retro:
        return const Color(0xFFFFF3E0);
      case FrameStyle.neon:
        return Colors.deepPurple.shade900;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview")),
      body: finalStrip == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 15),

            // Layout Selector
            Wrap(
              spacing: 8,
              children: StripLayout.values.map((layout) {
                return ChoiceChip(
                  label: Text(layout.name.toUpperCase()),
                  selected: selectedLayout == layout,
                  onSelected: (_) async {
                    selectedLayout = layout;
                    await generateStripAsync();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 15),

            // Frame Selector
            Wrap(
              spacing: 8,
              children: FrameStyle.values.map((frame) {
                return ChoiceChip(
                  label: Text(frame.name.toUpperCase()),
                  selected: selectedFrame == frame,
                  onSelected: (_) async {
                    selectedFrame = frame;
                    await generateStripAsync();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(selectedLayout.name + selectedFrame.name),
                decoration: BoxDecoration(
                  color: getFrameColor(),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(finalStrip!),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => CameraScreen(
                          stripCount: widget.stripCount,
                          countdown: widget.countdown,
                        ),
                      ),
                          (route) => false,
                    );
                  },
                  child: const Text("Retake"),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: downloadImage,
                  child: const Text("Download"),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: shareImage,
                  child: const Text("Share"),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
Uint8List generateStripIsolate(Map<String, dynamic> data) {
  final List<Map<String, dynamic>> images =
  List<Map<String, dynamic>>.from(data["images"]);

  final String layout = data["layout"];

  int targetWidth = 420;

  List<img.Image> processedImages = images.map((item) {
    Uint8List bytes = item["bytes"];
    String filterName = item["filter"];

    img.Image original = img.decodeImage(bytes)!;

    // Better filter processing
    switch (filterName) {
      case "grayscale":
        original = img.grayscale(original);
        break;
      case "sepia":
        original = img.sepia(original);
        original = img.adjustColor(original, contrast: 1.1);
        break;
      case "warm":
        original = img.adjustColor(original,
            saturation: 1.3, brightness: 0.05);
        break;
      case "cool":
        original = img.adjustColor(original,
            saturation: 0.8, brightness: -0.02);
        break;
      case "vintage":
        original = img.sepia(original);
        original = img.adjustColor(original,
            saturation: 0.9, contrast: 1.05);
        break;
      case "bright":
        original = img.adjustColor(original,
            brightness: 0.1, contrast: 1.1);
        break;
      case "cinematic":
        original = img.adjustColor(original,
            saturation: 0.7, contrast: 1.2);
        break;
    }

    int size =
    original.width < original.height ? original.width : original.height;

    img.Image cropped = img.copyCrop(
      original,
      x: (original.width - size) ~/ 2,
      y: (original.height - size) ~/ 2,
      width: size,
      height: size,
    );

    return img.copyResize(cropped, width: targetWidth);
  }).toList();

  img.Image finalImage;

  if (layout == "grid") {
    int size = processedImages.first.width;
    finalImage = img.Image(width: size * 2, height: size * 2);
    for (int i = 0; i < processedImages.length && i < 4; i++) {
      int x = (i % 2) * size;
      int y = (i ~/ 2) * size;
      img.compositeImage(finalImage, processedImages[i],
          dstX: x, dstY: y);
    }
  } else if (layout == "triple") {
    int size = processedImages.first.width;
    finalImage = img.Image(width: size, height: size * 3);
    for (int i = 0; i < processedImages.length && i < 3; i++) {
      img.compositeImage(finalImage, processedImages[i],
          dstY: i * size);
    }
  } else {
    int spacing = 40;
    int footerSpace = 80;

    int totalHeight =
        processedImages.fold(0, (sum, image) => sum + image.height) +
            spacing * (processedImages.length + 1) +
            footerSpace;

    finalImage = img.Image(
      width: targetWidth + 40,
      height: totalHeight,
    );

// White strip background
    img.fill(finalImage, color: img.ColorRgb8(255, 255, 255));

    int currentY = spacing;

    for (var image in processedImages) {
      img.compositeImage(
        finalImage,
        image,
        dstX: 20,
        dstY: currentY,
      );
      currentY += image.height + spacing;
    }

// Black thin border
    img.drawRect(
      finalImage,
      x1: 0,
      y1: 0,
      x2: finalImage.width - 1,
      y2: finalImage.height - 1,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
// ----- FOOTER -----
  final date = DateTime.now();
  String footer =
      "PhotoBooth  |  ${date.day}/${date.month}/${date.year}  |  Nash Edition";

  img.drawString(
    finalImage,
    footer,
    font: img.arial14,
    x: 20,
    y: finalImage.height - 30,
    color: img.ColorRgb8(90, 90, 90),
  );

  return Uint8List.fromList(img.encodePng(finalImage));
}
//finalImage