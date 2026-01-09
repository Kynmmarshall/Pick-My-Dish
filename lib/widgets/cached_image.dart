import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedProfileImage extends StatelessWidget {
  final String imagePath;
  final double radius;
  final bool isProfilePicture;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageProvider? testImageProvider;
  final bool testShowPlaceholder;
  final bool testShowError;

  const CachedProfileImage({
    super.key,
    required this.imagePath,
    this.radius = 60,
    this.isProfilePicture = true,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.testImageProvider,
    this.testShowPlaceholder = false,
    this.testShowError = false,
  });

  @override
  Widget build(BuildContext context) {
    if (testShowPlaceholder) {
      return _buildPlaceholder();
    }

    if (testShowError) {
      return _buildErrorWidget();
    }

    if (testImageProvider != null) {
      return _buildFromProvider(testImageProvider!);
    }
    
    // Check if it's a server path
    if (imagePath.startsWith('assets/')) {
      // Local asset
      return isProfilePicture
          ? CircleAvatar(
              radius: radius,
              backgroundImage: AssetImage(imagePath),
            )
          : Image.asset(
              imagePath,
              width: width,
              height: height,
              fit: fit,
            );
    } else {
      // Server image
      final url = 'http://38.242.246.126:3000/$imagePath';
      
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) {
          return _buildFromProvider(imageProvider);
        },
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildFromProvider(ImageProvider imageProvider) {
    return isProfilePicture
        ? CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
          )
        : Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isProfilePicture ? radius : 10),
              image: DecorationImage(
                image: imageProvider,
                fit: fit,
              ),
            ),
          );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: isProfilePicture ? radius * 2 : width,
      height: isProfilePicture ? radius * 2 : height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(isProfilePicture ? radius : 10),
      ),
      child: Center(child: CircularProgressIndicator(color: Colors.orange)),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: isProfilePicture ? radius * 2 : width,
      height: isProfilePicture ? radius * 2 : height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(isProfilePicture ? radius : 10),
      ),
      child: Icon(Icons.broken_image, color: Colors.white),
    );
  }
}