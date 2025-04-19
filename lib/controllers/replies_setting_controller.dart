import 'package:get/get.dart';
import 'package:repliq/models/comment_model.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/helper.dart';

class RepliesSettingController extends GetxController {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final loading = false.obs;
  final replies = <CommentModel>[].obs;

  Future<void> loadReplies() async {
    try {
      loading.value = true;
      final userId = supabaseService.currentUser.value?.id;
      if (userId == null) return;

      final data = await SupabaseService.client
          .from('comments')
          .select('''
            id, reply, created_at, user_id, post_id,
            user:user_id (
              id, email, metadata
            ),
            post:post_id (
              id, content, image, created_at, user_id, comment_count, like_count,
              user:user_id (
                id, email, metadata
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      replies.value = [];
      for (final item in data) {
        replies.add(CommentModel.fromJson(item));
      }
    } catch (e) {
      print('Error loading replies: $e');
      showSnackBar('Error', 'Failed to load replies');
    } finally {
      loading.value = false;
    }
  }
} 