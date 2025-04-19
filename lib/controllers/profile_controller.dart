import 'dart:io';

import 'package:get/get.dart';
import 'package:repliq/models/comment_model.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/models/user_model.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/env.dart';
import 'package:repliq/utils/helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  Rx<File?> image = Rx<File?>(null);
  var loading = false.obs;
  RxList<PostModel> posts = RxList<PostModel>();
  var postLoading = false.obs;
  var replyLoading = false.obs;
  RxList<CommentModel?> comments = RxList<CommentModel?>();
  var userLoading = false.obs;
  Rx<UserModel?> user = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _subscribeToProfileUpdates();
  }

  void _subscribeToProfileUpdates() {
    final channel = SupabaseService.client.channel('public:profiles')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        callback: (payload) {
          if (payload.newRecord != null) {
            final updatedUser = UserModel.fromJson({
              'id': payload.newRecord!['id'],
              'email': payload.newRecord!['email'],
              'metadata': payload.newRecord!['raw_user_meta_data']
            });
            user.value = updatedUser;
            user.refresh();
          }
        },
      )
      .subscribe();
  }

  // * Fetch user posts
  Future<void> fetchPosts(String userId) async {
    try {
      postLoading.value = true;
      final List<dynamic> data = await SupabaseService.client.from("posts").select('''
        id, content, image, created_at, comment_count, like_count,
        user:user_id (email, metadata), likes:likes (user_id, post_id)
      ''').eq("user_id", userId).order("id", ascending: false);
      postLoading.value = false;

      if (data.isNotEmpty) {
        posts.value = [for (var item in data) PostModel.fromJson(item)];
      }
    } catch (e) {
      postLoading.value = false;
      print("Error fetching posts: $e");
    }
  }

  // * Fetch user replies
  Future<void> fetchComments(String userId) async {
    try {
      replyLoading.value = true;
      final List<dynamic> data = await SupabaseService.client.from("comments").select('''
        id, user_id, post_id, reply, created_at, user:user_id (email, metadata)
      ''').eq("user_id", userId).order("id", ascending: false);
      replyLoading.value = false;

      if (data.isNotEmpty) {
        comments.value = [for (var item in data) CommentModel.fromJson(item)];
      }
    } catch (e) {
      replyLoading.value = false;
      print("Error fetching comments: $e");
    }
  }

  // * Get user
  Future<void> getUser(String userId) async {
    try {
      userLoading.value = true;
      final data = await SupabaseService.client
          .rpc('get_user_by_id', params: {'user_id': userId})
          .single();
      
      if (data != null) {
        // Ensure metadata is properly structured
        final metadata = data['raw_user_meta_data'] ?? {};
        user.value = UserModel.fromJson({
          'id': data['id']?.toString() ?? '',
          'email': data['email']?.toString() ?? '',
          'metadata': {
            'name': metadata['name']?.toString() ?? 'Unknown',
            'image': metadata['image']?.toString() ?? '',
            'description': metadata['description']?.toString() ?? ''
          }
        });
      }
      userLoading.value = false;

      // * Fetch posts and comments
      await fetchPosts(userId);
      await fetchComments(userId);
    } catch (e) {
      userLoading.value = false;
      print("Error fetching user: $e");
      // Set default user data on error
      user.value = UserModel.fromJson({
        'id': userId,
        'email': '',
        'metadata': {
          'name': 'Unknown',
          'image': '',
          'description': ''
        }
      });
    }
  }

  Future<void> updateProfile(String userId, String description) async {
    try {
      loading.value = true;

      // * Check if image exists then upload it first
      if (image.value != null && image.value!.existsSync()) {
        final String dir = "$userId/profile.jpg";
        final String path = await SupabaseService.client.storage.from(Env.s3Bucket).upload(
          dir,
          image.value!,
          fileOptions: const FileOptions(upsert: true),
        );
        await SupabaseService.client.auth.updateUser(
          UserAttributes(
            data: {"image": path},
          ),
        );
      }

      // * Update description
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          data: {
            "description": description,
          },
        ),
      );

      loading.value = false;
      showSnackBar("Success", "Profile updated successfully!");
    } on AuthException catch (error) {
      loading.value = false;
      showSnackBar("Error", error.message);
    } on StorageException catch (error) {
      loading.value = false;
      showSnackBar("Error", error.message);
    }
  }

  // * Delete thread
  Future<void> deleteThread(String postId) async {
    try {
      // First check if the post exists and belongs to the current user
      final post = await SupabaseService.client
          .from("posts")
          .select("image, user_id")
          .eq("id", postId)
          .single();

      if (post == null) {
        throw Exception("Post not found");
      }

      // Verify the post belongs to the current user
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null || post['user_id'] != currentUser.id) {
        throw Exception("You don't have permission to delete this post");
      }

      // Delete all notifications associated with the post
      try {
        await SupabaseService.client
            .from("notifications")
            .delete()
            .eq("post_id", postId);
      } catch (e) {
        print("Error deleting notifications: $e");
        // Continue even if notifications deletion fails
      }

      // Delete all likes associated with the post
      try {
        await SupabaseService.client
            .from("likes")
            .delete()
            .eq("post_id", postId);
      } catch (e) {
        print("Error deleting likes: $e");
        // Continue even if likes deletion fails
      }

      // Delete all comments associated with the post
      try {
        await SupabaseService.client
            .from("comments")
            .delete()
            .eq("post_id", postId);
      } catch (e) {
        print("Error deleting comments: $e");
        // Continue even if comments deletion fails
      }

      // Delete the post image from storage if it exists
      if (post['image'] != null) {
        try {
          await SupabaseService.client.storage
              .from(Env.s3Bucket)
              .remove([post['image']]);
        } catch (e) {
          print("Error deleting post image: $e");
          // Continue even if image deletion fails
        }
      }

      // Finally delete the post itself
      await SupabaseService.client
          .from("posts")
          .delete()
          .eq("id", postId)
          .eq("user_id", currentUser.id); // Add user_id check for extra security

      // Update the local posts list
      posts.removeWhere((element) => element.id == postId);
      
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      showSnackBar("Success", "Thread deleted successfully!");
    } catch (e) {
      print("Error deleting thread: $e");
      showSnackBar("Error", "Failed to delete thread: ${e.toString()}");
    }
  }

  // * Delete reply
  Future<void> deleteReply(int replyId) async {
    try {
      // First get the post_id from the comment
      final commentData = await SupabaseService.client
          .from("comments")
          .select("post_id")
          .eq("id", replyId)
          .single();
      
      if (commentData != null && commentData['post_id'] != null) {
        final postId = commentData['post_id'].toString();
        
        // Delete the comment
        await SupabaseService.client
            .from("comments")
            .delete()
            .eq("id", replyId);

        // Decrement the comment count in the post table
        await SupabaseService.client
            .rpc("comment_decrement", params: {"count": 1, "row_id": postId});

        // Update local state
        comments.removeWhere((element) => element?.id == replyId);
        
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        showSnackBar("Success", "Reply deleted successfully!");
      }
    } catch (e) {
      showSnackBar("Error", "Something went wrong. Please try again.");
    }
  }

  // * Image picker
  void pickImage() async {
    File? file = await pickImageFromGallary();
    if (file != null) image.value = file;
  }
}