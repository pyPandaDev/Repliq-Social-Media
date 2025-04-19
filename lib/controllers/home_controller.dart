import 'package:get/get.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/models/like_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController extends GetxController {
  RxList<PostModel> posts = RxList<PostModel>();
  var loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    // Subscribe to new posts
    final postsChannel = SupabaseService.client.channel('public:posts')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'posts',
        callback: (payload) async {
          if (payload.newRecord != null) {
            // Fetch the complete post data including user and likes
            final newPostData = await SupabaseService.client
                .from('posts')
                .select('''
                  id, content, image, created_at, comment_count, like_count, user_id,
                  user:user_id (email, metadata),
                  likes:likes (user_id, post_id)
                ''')
                .eq('id', payload.newRecord!['id'])
                .single();

            if (newPostData != null) {
              final newPost = PostModel.fromJson(newPostData);
              // Insert at the beginning of the list
              posts.insert(0, newPost);
              posts.refresh();
            }
          }
        },
      )
      .subscribe();

    // Subscribe to likes changes
    final likesChannel = SupabaseService.client.channel('public:likes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (payload) {
          if (payload.newRecord != null) {
            final postId = payload.newRecord!['post_id'] as int;
            final userId = payload.newRecord!['user_id'] as String;
            final eventType = payload.eventType;

            // Find the post in the list
            final postIndex = posts.indexWhere((post) => post.id == postId.toString());
            if (postIndex != -1) {
              final post = posts[postIndex];
              if (eventType == PostgresChangeEvent.insert) {
                // Add like
                post.likes ??= [];
                post.likes!.add(LikeModel(userId: userId, postId: postId.toString()));
                post.likeCount = (post.likeCount ?? 0) + 1;
              } else if (eventType == PostgresChangeEvent.delete) {
                // Remove like
                post.likes?.removeWhere((like) => like.userId == userId);
                post.likeCount = (post.likeCount ?? 0) - 1;
              }
              posts[postIndex] = post;
              posts.refresh();
            }
          }
        },
      )
      .subscribe();

    // Subscribe to post updates for like count changes
    final postUpdatesChannel = SupabaseService.client.channel('public:posts')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'posts',
        callback: (payload) {
          if (payload.newRecord != null) {
            final postId = payload.newRecord!['id'] as int;
            final likeCount = payload.newRecord!['like_count'] as int;
            
            final postIndex = posts.indexWhere((post) => post.id == postId.toString());
            if (postIndex != -1) {
              posts[postIndex].likeCount = likeCount;
              posts.refresh();
            }
          }
        },
      )
      .subscribe();
  }

  Future<void> fetchPosts() async {
    try {
      loading.value = true;
      final List<dynamic> data = await SupabaseService.client.from("posts").select('''
        id, content, image, created_at, comment_count, like_count, user_id,
        user:user_id (email, metadata)
      ''').order("id", ascending: false);
      loading.value = false;

      if (data.isNotEmpty) {
        posts.value = [for (var item in data) PostModel.fromJson(item)];
        
        // Fetch likes for each post separately
        for (var post in posts) {
          final likesData = await SupabaseService.client
              .from('likes')
              .select('user_id, post_id')
              .eq('post_id', int.parse(post.id!));
          
          post.likes = [for (var like in likesData) 
            LikeModel(userId: like['user_id'] as String, postId: like['post_id'].toString())
          ];
        }
        posts.refresh();
      }
    } catch (e) {
      loading.value = false;
      print("Error fetching posts: $e");
    }
  }

  // * Listen post changes
}