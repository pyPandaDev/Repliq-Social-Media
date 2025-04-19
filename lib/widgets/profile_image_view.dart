import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:get/get.dart';

class ProfileImageView extends StatelessWidget {
  final String imageUrl;
  final String userName;

  const ProfileImageView({
    required this.imageUrl,
    required this.userName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          userName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
} 