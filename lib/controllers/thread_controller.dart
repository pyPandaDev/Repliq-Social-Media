import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:repliq/models/comment_model.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/services/navigation_service.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/env.dart';
import 'package:repliq/utils/helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:repliq/controllers/home_controller.dart';

class ThreadController extends GetxController {
  final TextEditingController contentController =
      TextEditingController(text: "");
  var content = "".obs;
  var loading = false.obs;
  Rx<File?> image = Rx<File?>(null);
  var showPostLoading = false.obs;
  Rx<PostModel> post = Rx<PostModel>(PostModel());
  var commentLoading = false.obs;
  RxList<CommentModel?> comments = RxList<CommentModel?>();

  void pickImage() async {
    File? file = await pickImageFromGallary();
    if (file != null) {
      image.value = file;
    }
  }

  // * Add post
  Future<void> store(String userId) async {
    try {
      loading.value = true;
      const uuid = Uuid();
      final dir = "$userId/${uuid.v6()}";
      var imgPath = "";

      if (image.value != null && image.value!.existsSync()) {
        imgPath = await SupabaseService.client.storage
            .from(Env.s3Bucket)
            .upload(dir, image.value!);
      }

      // * Store post in table
      final response = await SupabaseService.client.from("posts").insert({
        "user_id": userId,
        "content": content.value,
        "image": imgPath.isNotEmpty ? imgPath : null,
      }).select('''
        id, content, image, created_at, comment_count, like_count, user_id,
        user:user_id (email, metadata)
      ''').single();

      if (response != null) {
        // Get the HomeController and update its posts list
        final homeController = Get.find<HomeController>();
        final newPost = PostModel.fromJson(response);
        homeController.posts.insert(0, newPost);
        homeController.posts.refresh();
      }

      loading.value = false;
      resetState();
      Get.find<NavigationService>().currentIndex.value = 0;

      showSnackBar("Success", "Post Added successfully!");
    } on StorageException catch (error) {
      loading.value = false;
      showSnackBar("Error", error.message);
    } catch (error) {
      loading.value = false;
      showSnackBar("Error", "Something went wrong!");
    }
  }

  // * Show Post
  Future<void> show(String postId) async {
    try {
      comments.value = [];
      post.value = PostModel();
      showPostLoading.value = true;
      final data = await SupabaseService.client.from("posts").select('''
    id ,content , image ,created_at ,comment_count , like_count,user_id,
    user:user_id (email , metadata) , likes:likes (user_id ,post_id)
''').eq("id", postId).single();
      showPostLoading.value = false;
      post.value = PostModel.fromJson(data);

      // * Load post comments
      postComments(postId);
    } catch (e) {
      showPostLoading.value = false;
      showSnackBar("Error", "Something went wrong!");
    }
  }

  // * Post comments
  Future<void> postComments(String postId) async {
    try {
      commentLoading.value = true;
      final List<dynamic> data =
          await SupabaseService.client.from("comments").select('''
    id, reply, created_at, user_id, post_id,
    user:user_id (
      id,
      email,
      metadata
    )
''').eq("post_id", postId).order('created_at', ascending: true);

      print("Comments data received: ${data.length} comments"); // Debug print

      comments.value = [];
      if (data.isNotEmpty) {
        for (var item in data) {
          if (item != null) {
            final comment = CommentModel.fromJson(item);
            print("Processing comment: ${comment.reply} from user: ${comment.userId}"); // Debug print
            comments.add(comment);
          }
        }
      }
      print("Final comments list length: ${comments.length}"); // Debug print
      commentLoading.value = false;
    } catch (e) {
      print("Error loading comments: $e");
      commentLoading.value = false;
      showSnackBar("Error", "Something went wrong!");
    }
  }

  // * Like and dislike the post
  Future<void> likeDislike(
      String status, String postId, String postUserId, String userId) async {
    try {
      if (status == "1") {
        // Insert like
        await SupabaseService.client
            .from("likes")
            .insert({"user_id": userId, "post_id": postId});

        // Add notification
        await SupabaseService.client.from("notifications").insert({
          "user_id": userId,
          "notification": "liked on your post.",
          "to_user_id": postUserId,
          "post_id": postId,
        });

        // Increment like counter
        await SupabaseService.client
            .rpc("like_increment", params: {"count": 1, "row_id": postId});
      } else if (status == "0") {
        // Remove like
        await SupabaseService.client
            .from("likes")
            .delete()
            .match({"user_id": userId, "post_id": postId});

        // Decrement like counter
        await SupabaseService.client
            .rpc("like_decrement", params: {"count": 1, "row_id": postId});
      }
    } catch (e) {
      print("Error in like/dislike: $e");
      showSnackBar("Error", "Failed to update like status");
    }
  }

  // * Reset the state
  void resetState() {
    content.value = "";
    contentController.text = "";
    image.value = null;
  }
}
