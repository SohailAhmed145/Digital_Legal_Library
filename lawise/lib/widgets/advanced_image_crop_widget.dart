import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

class AdvancedImageCropWidget extends StatefulWidget {
  final Uint8List imageData;
  final String title;

  const AdvancedImageCropWidget({
    super.key,
    required this.imageData,
    this.title = 'Crop Image',
  });

  @override
  State<AdvancedImageCropWidget> createState() => _AdvancedImageCropWidgetState();
}

class _AdvancedImageCropWidgetState extends State<AdvancedImageCropWidget> {
  late ui.Image _image;
  bool _isImageLoaded = false;
  Offset _cropStart = Offset.zero;
  Offset _cropEnd = Offset.zero;
  bool _isCropping = false;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _isCircleShape = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageData);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isImageLoaded = true;
      // Initialize crop area to center of image
      _cropStart = Offset(_image.width * 0.25, _image.height * 0.25);
      _cropEnd = Offset(_image.width * 0.75, _image.height * 0.75);
    });
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
              'Crop',
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
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Stack(
                    children: [
                      // Image with transformations
                      Transform(
                        transform: Matrix4.identity()
                          ..translate(_offset.dx, _offset.dy)
                          ..scale(_scale),
                        child: CustomPaint(
                          size: Size(_image.width.toDouble(), _image.height.toDouble()),
                          painter: ImagePainter(_image),
                        ),
                      ),
                      // Crop overlay
                      Positioned(
                        left: _cropStart.dx * _scale + _offset.dx,
                        top: _cropStart.dy * _scale + _offset.dy,
                        child: Container(
                          width: (_cropEnd.dx - _cropStart.dx) * _scale,
                          height: (_cropEnd.dy - _cropStart.dy) * _scale,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor, width: 3),
                            borderRadius: _isCircleShape 
                                ? BorderRadius.circular((_cropEnd.dx - _cropStart.dx) * _scale / 2)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: _isCircleShape 
                                ? BorderRadius.circular((_cropEnd.dx - _cropStart.dx) * _scale / 2)
                                : BorderRadius.zero,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Crop area corners for resizing
                      ..._buildCornerHandles(),
                      // Instructions
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              'Drag to move, pinch to zoom, drag corners to resize',
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

  List<Widget> _buildCornerHandles() {
    final corners = [
      _cropStart,
      Offset(_cropEnd.dx, _cropStart.dy),
      _cropEnd,
      Offset(_cropStart.dx, _cropEnd.dy),
    ];

    return corners.map((corner) {
      return Positioned(
        left: corner.dx * _scale + _offset.dx - 15,
        top: corner.dy * _scale + _offset.dy - 15,
        child: GestureDetector(
          onPanUpdate: (details) => _resizeCrop(corner, details.delta),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.drag_handle,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }



  void _onScaleStart(ScaleStartDetails details) {
    _isCropping = false;
    // Check if this is a pan gesture (no scaling)
    if (details.pointerCount == 1) {
      _isCropping = true;
      _cropStart = details.localFocalPoint;
      _cropEnd = details.localFocalPoint;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount == 1 && _isCropping) {
        // Single finger pan - update crop area
        _cropEnd = details.localFocalPoint;
      } else if (details.pointerCount == 2) {
        // Two finger gesture - handle scaling and panning
        _scale = (_scale * details.scale).clamp(0.5, 3.0);
        _offset += details.focalPointDelta;
      }
    });
  }

  void _resizeCrop(Offset corner, Offset delta) {
    setState(() {
      if (corner == _cropStart) {
        _cropStart += delta / _scale;
      } else if (corner == _cropEnd) {
        _cropEnd += delta / _scale;
      } else if (corner.dx == _cropStart.dx) {
        _cropStart = Offset(_cropStart.dx, _cropStart.dy + delta.dy / _scale);
      } else {
        _cropEnd = Offset(_cropEnd.dx, _cropEnd.dy + delta.dy / _scale);
      }
      
      // Ensure crop area is valid
      _cropStart = Offset(
        _cropStart.dx.clamp(0, _image.width.toDouble()),
        _cropStart.dy.clamp(0, _image.height.toDouble()),
      );
      _cropEnd = Offset(
        _cropEnd.dx.clamp(0, _image.width.toDouble()),
        _cropEnd.dy.clamp(0, _image.height.toDouble()),
      );
    });
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
