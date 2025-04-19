import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/helper.dart';


class CommentController extends GetxController {
  final TextEditingController replyController = TextEditingController(text: '');
  var reply = "".obs;
  var loading = false.obs;

  void addReply(String userId, String postId, String postUserId) async {
    try {
      loading.value = true;
      // * Increase the post comment count
      await SupabaseService.client
          .rpc("comment_increment", params: {"count": 1, "row_id": postId});

      // * Add Comment notification
      await SupabaseService.client.from("notifications").insert({
        "user_id": userId,
        "notification": "You got a comment.",
        "to_user_id": postUserId,
        "post_id": postId,
      });

      await SupabaseService.client
          .from("comments")
          .insert({"post_id": postId, "user_id": userId, "reply": reply.value});
      loading.value = false;
      Get.back();
      showSnackBar("Success", "Replied Done!");
    } catch (e) {
      loading.value = false;
      showSnackBar("Error", "Something went wrong.please try again!");
    }
  }
}
