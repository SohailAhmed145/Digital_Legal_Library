import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/user_profile_provider.dart';
import '../services/data_persistence_service.dart';

class ProfileImageWidget extends ConsumerWidget {
  final double size;
  final double borderWidth;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;

  const ProfileImageWidget({
    super.key,
    this.size = 40,
    this.borderWidth = 2,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    
    print('ProfileImageWidget - Building with profile: ${userProfile?.fullName}, Image path: ${userProfile?.profileImagePath}');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Colors.white,
                  width: borderWidth,
                )
              : null,
          boxShadow: showBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((size - (showBorder ? borderWidth * 2 : 0)) / 2),
          child: userProfile?.profileImagePath != null && 
               userProfile!.profileImagePath!.isNotEmpty
              ? _buildProfileImage(userProfile.profileImagePath!)
              : _buildEmptyProfile(),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String imagePath) {
    if (kIsWeb) {
      if (imagePath.startsWith('http')) {
        // Firebase Storage URL - use network image with better error handling
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('ProfileImageWidget - Failed to load Firebase image: $error');
            // Try to fallback to local image data if available
            return FutureBuilder<Uint8List?>(
              future: _getWebImageData(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildEmptyProfile();
                    },
                  );
                } else {
                  return _buildEmptyProfile();
                }
              },
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingPlaceholder();
          },
        );
      } else if (imagePath.startsWith('web_image_')) {
        // Local web image - try to get from persistence
        return FutureBuilder<Uint8List?>(
          future: _getWebImageData(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildEmptyProfile();
                },
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder();
            } else {
              print('ProfileImageWidget - No local image data found for path: $imagePath');
              return _buildEmptyProfile();
            }
          },
        );
      } else {
        // Invalid path - show empty profile
        print('ProfileImageWidget - Invalid image path: $imagePath');
        return _buildEmptyProfile();
      }
    } else {
      // For mobile, use file image
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildEmptyProfile();
        },
      );
    }
  }

  Widget _buildEmptyProfile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFBBDEFB),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        color: const Color(0xFF1976D2),
        size: size * 0.5,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _getWebImageData() async {
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      final imageData = persistenceService.getProfileImageData();
      if (imageData != null) {
        print('ProfileImageWidget - Successfully loaded local image data: ${imageData.length} bytes');
      } else {
        print('ProfileImageWidget - No local image data found');
      }
      return imageData;
    } catch (e) {
      print('ProfileImageWidget - Error getting web image data: $e');
      return null;
    }
  }
}
