import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

class SimpleImageCropWidget extends StatefulWidget {
  final Uint8List imageData;
  final String title;

  const SimpleImageCropWidget({
    super.key,
    required this.imageData,
    this.title = 'Crop Image',
  });

  @override
  State<SimpleImageCropWidget> createState() => _SimpleImageCropWidgetState();
}

class _SimpleImageCropWidgetState extends State<SimpleImageCropWidget> {
  late ui.Image _image;
  bool _isImageLoaded = false;
  Offset _cropStart = Offset.zero;
  Offset _cropEnd = Offset.zero;
  bool _isDragging = false;
  bool _isCircleShape = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageData);
      final frame = await codec.getNextFrame();
      setState(() {
        _image = frame.image;
        _isImageLoaded = true;
        // Initialize crop area to center of image
        _cropStart = Offset(_image.width * 0.25, _image.height * 0.25);
        _cropEnd = Offset(_image.width * 0.75, _image.height * 0.75);
      });
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCircleShape ? Icons.crop_square : Icons.circle,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isCircleShape = !_isCircleShape;
              });
            },
          ),
          TextButton(
            onPressed: _isImageLoaded ? _cropImage : null,
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isImageLoaded
          ? GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                  _cropStart = details.localPosition;
                  _cropEnd = details.localPosition;
                });
              },
              onPanUpdate: (details) {
                if (_isDragging) {
                  setState(() {
                    _cropEnd = details.localPosition;
                  });
                }
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Stack(
                    children: [
                      // Image
                      CustomPaint(
                        size: Size(_image.width.toDouble(), _image.height.toDouble()),
                        painter: ImagePainter(_image),
                      ),
                      // Crop overlay
                      Positioned(
                        left: _cropStart.dx,
                        top: _cropStart.dy,
                        child: Container(
                          width: (_cropEnd.dx - _cropStart.dx).abs(),
                          height: (_cropEnd.dy - _cropStart.dy).abs(),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor, width: 3),
                            borderRadius: _isCircleShape 
                                ? BorderRadius.circular(((_cropEnd.dx - _cropStart.dx).abs() / 2).clamp(0, double.infinity))
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: _isCircleShape 
                                ? BorderRadius.circular(((_cropEnd.dx - _cropStart.dx).abs() / 2).clamp(0, double.infinity))
                                : BorderRadius.zero,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Instructions
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              'Drag to select crop area',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap shape icon to toggle between circle and square',
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
    );
  }

  Future<void> _cropImage() async {
    try {
      // Calculate actual crop coordinates
      final left = _cropStart.dx.clamp(0.0, _image.width.toDouble());
      final top = _cropStart.dy.clamp(0.0, _image.height.toDouble());
      final right = _cropEnd.dx.clamp(0.0, _image.width.toDouble());
      final bottom = _cropEnd.dy.clamp(0.0, _image.height.toDouble());
      
      final width = (right - left).abs();
      final height = (bottom - top).abs();
      
      if (width < 50 || height < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop area too small. Please select a larger area.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Create a paint for the cropped image
      final paint = Paint()
        ..filterQuality = FilterQuality.high;
      
      // Draw the cropped portion
      final srcRect = Rect.fromLTWH(
        left.toDouble(),
        top.toDouble(),
        width.toDouble(),
        height.toDouble(),
      );
      
      final dstRect = Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble());
      
      canvas.drawImageRect(_image, srcRect, dstRect, paint);
      
      // Convert to picture and then to image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final croppedBytes = byteData.buffer.asUint8List();
        Navigator.of(context).pop(croppedBytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cropping image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  
  ImagePainter(this.image);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high;
    
    canvas.drawImage(image, Offset.zero, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
