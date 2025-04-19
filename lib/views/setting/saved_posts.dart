import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/saved_posts_controller.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/post_card.dart';

class SavedPosts extends StatelessWidget {
  const SavedPosts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Saved Posts'),
        elevation: 0,
      ),
      body: GetX<SavedPostsController>(
        init: SavedPostsController(),
        builder: (controller) {
          if (controller.loading.value) {
            return const Loading();
          }

          if (controller.savedPosts.isEmpty) {
            return const Center(
              child: Text(
                'No saved posts yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.savedPosts.length,
            itemBuilder: (context, index) {
              final savedPost = controller.savedPosts[index];
              if (savedPost.post == null) return const SizedBox();
              return PostCard(
                post: savedPost.post!,
                callback: (postId) async {
                  // Refresh the saved posts after any changes
                  await controller.loadSavedPosts();
                },
              );
            },
          );
        },
      ),
    );
  }
} 