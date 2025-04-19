import 'package:get/get.dart';
import 'package:repliq/models/saved_post_model.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:flutter/material.dart';

class SavedPostsController extends GetxController {
  final RxBool loading = false.obs;
  final RxList<SavedPostModel> savedPosts = <SavedPostModel>[].obs;
  final _supabaseService = Get.find<SupabaseService>();

  @override
  void onInit() {
    super.onInit();
    loadSavedPosts();
  }

  Future<void> loadSavedPosts() async {
    try {
      loading.value = true;
      final userId = _supabaseService.currentUser.value?.id;
      if (userId == null) return;

      // First, get all saved post IDs
      final savedPostsResponse = await SupabaseService.client
          .from('saved_posts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (savedPostsResponse != null && savedPostsResponse is List) {
        // Create a list to store complete saved posts
        final List<SavedPostModel> completeSavedPosts = [];

        // For each saved post, fetch the associated post details
        for (var savedPost in savedPostsResponse) {
          try {
            // First get the post details with user metadata
            final postResponse = await SupabaseService.client
                .from('posts')
                .select('*, user:user_id (email, metadata)')
                .eq('id', savedPost['post_id'])
                .single();

            if (postResponse != null) {
              // Get likes count
              final likesResponse = await SupabaseService.client
                  .rpc('get_post_likes_count', params: {'post_id_param': savedPost['post_id']})
                  .single();

              // Get comments count
              final commentsResponse = await SupabaseService.client
                  .rpc('get_post_comments_count', params: {'post_id_param': savedPost['post_id']})
                  .single();

              // Add counts to post response
              postResponse['likes_count'] = likesResponse['count'] ?? 0;
              postResponse['comments_count'] = commentsResponse['count'] ?? 0;

              // Combine saved post data with post details
              savedPost['post'] = postResponse;
              completeSavedPosts.add(SavedPostModel.fromJson(savedPost));
            }
          } catch (e) {
            print('Error fetching post ${savedPost['post_id']}: $e');
          }
        }

        savedPosts.value = completeSavedPosts;
        
        if (savedPosts.isEmpty) {
          print('No saved posts found');
        } else {
          print('Loaded ${savedPosts.length} saved posts');
        }
      }
    } catch (e, stackTrace) {
      print('Error loading saved posts: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load saved posts',
        backgroundColor: Colors.red[900],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      loading.value = false;
    }
  }

  Future<bool> savePost(int postId) async {
    try {
      final userId = _supabaseService.currentUser.value?.id;
      if (userId == null) {
        Get.snackbar(
          'Error',
          'You must be logged in to save posts',
          backgroundColor: Colors.red[900],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return false;
      }

      // Check if post is already saved
      final existingSave = await SupabaseService.client
          .from('saved_posts')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existingSave != null) {
        // Post is already saved, remove it
        await SupabaseService.client
            .from('saved_posts')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
        
        // Remove from local list
        savedPosts.removeWhere((saved) => saved.postId == postId);
        
        // Show unsave message
        Get.snackbar(
          'Post Unsaved',
          'Post removed from saved items',
          backgroundColor: Colors.grey[900],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          isDismissible: true,
        );
        return false;
      }

      // Save the post
      await SupabaseService.client
          .from('saved_posts')
          .insert({
            'user_id': userId,
            'post_id': postId,
          });

      // Get the post details
      final postResponse = await SupabaseService.client
          .from('posts')
          .select('*, user:user_id (email, metadata)')
          .eq('id', postId)
          .single();

      if (postResponse != null) {
        // Get likes and comments count
        final likesResponse = await SupabaseService.client
            .rpc('get_post_likes_count', params: {'post_id_param': postId})
            .single();
        final commentsResponse = await SupabaseService.client
            .rpc('get_post_comments_count', params: {'post_id_param': postId})
            .single();

        // Add counts to post response
        postResponse['likes_count'] = likesResponse['count'] ?? 0;
        postResponse['comments_count'] = commentsResponse['count'] ?? 0;

        // Get the saved post details
        final savedPostResponse = await SupabaseService.client
            .from('saved_posts')
            .select()
            .eq('user_id', userId)
            .eq('post_id', postId)
            .single();

        // Combine the data
        savedPostResponse['post'] = postResponse;
        
        // Add to local list
        savedPosts.insert(0, SavedPostModel.fromJson(savedPostResponse));
        
        // Show save message
        Get.snackbar(
          'Post Saved',
          'Post added to saved items',
          backgroundColor: Colors.grey[900],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          isDismissible: true,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving/unsaving post: $e');
      Get.snackbar(
        'Error',
        'Failed to save/unsave post',
        backgroundColor: Colors.red[900],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return false;
    }
  }

  Future<bool> isPostSaved(int postId) async {
    try {
      final userId = _supabaseService.currentUser.value?.id;
      if (userId == null) return false;

      final response = await SupabaseService.client
          .from('saved_posts')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if post is saved: $e');
      return false;
    }
  }
} 