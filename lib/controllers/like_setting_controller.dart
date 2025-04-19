import 'package:get/get.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/helper.dart';

class LikeSettingController extends GetxController {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final loading = false.obs;
  final likedPosts = <PostModel>[].obs;

  Future<void> loadLikedPosts() async {
    try {
      loading.value = true;
      final userId = supabaseService.currentUser.value?.id;
      if (userId == null) return;

      final data = await SupabaseService.client
          .from('likes')
          .select('''
            post_id,
            post:posts (
              id, content, image, created_at, user_id, comment_count, like_count,
              user:user_id (
                id, email, metadata
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      likedPosts.value = [];
      for (final item in data) {
        if (item['post'] != null) {
          likedPosts.add(PostModel.fromJson(item['post']));
        }
      }
    } catch (e) {
      print('Error loading liked posts: $e');
      showSnackBar('Error', 'Failed to load liked posts');
    } finally {
      loading.value = false;
    }
  }
} 