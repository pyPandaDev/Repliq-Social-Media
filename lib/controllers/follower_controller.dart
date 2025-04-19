import 'package:get/get.dart';
import 'package:repliq/models/follower_model.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/helper.dart';

class FollowerController extends GetxController {
  var followers = <FollowerModel>[].obs;
  var following = <FollowerModel>[].obs;
  var followerCount = 0.obs;
  var followingCount = 0.obs;
  var isFollowing = false.obs;
  var loading = false.obs;

  // Fetch followers for a user
  Future<void> fetchFollowers(String userId) async {
    try {
      loading.value = true;
      // First get the followers
      final response = await SupabaseService.client
          .from('followers')
          .select()
          .eq('following_id', userId);

      if (response != null) {
        // Then fetch user details for each follower
        final followersList = await Future.wait(
          (response as List).map((item) async {
            try {
              final userData = await SupabaseService.client
                  .rpc('get_user_by_id', params: {'user_id': item['user_id']})
                  .single();

              if (userData == null) return null;

              return FollowerModel.fromJson({
                ...item,
                'follower': {
                  'id': userData['id']?.toString(),
                  'email': userData['email']?.toString() ?? '',
                  'metadata': userData['raw_user_meta_data'] ?? {},
                }
              });
            } catch (e) {
              print('Error fetching user data: $e');
              return null;
            }
          })
        );

        followers.value = followersList.whereType<FollowerModel>().toList();
        followerCount.value = followers.length;
      }
      loading.value = false;
    } catch (e) {
      loading.value = false;
      print('Error fetching followers: $e');
    }
  }

  // Fetch following for a user
  Future<void> fetchFollowing(String userId) async {
    try {
      loading.value = true;
      // First get the following relationships
      final response = await SupabaseService.client
          .from('followers')
          .select()
          .eq('user_id', userId);

      if (response != null) {
        // Then fetch user details for each following
        final followingList = await Future.wait(
          (response as List).map((item) async {
            try {
              final userData = await SupabaseService.client
                  .rpc('get_user_by_id', params: {'user_id': item['following_id']})
                  .single();

              if (userData == null) return null;

              return FollowerModel.fromJson({
                ...item,
                'following': {
                  'id': userData['id']?.toString(),
                  'email': userData['email']?.toString() ?? '',
                  'metadata': userData['raw_user_meta_data'] ?? {},
                }
              });
            } catch (e) {
              print('Error fetching user data: $e');
              return null;
            }
          })
        );

        following.value = followingList.whereType<FollowerModel>().toList();
        followingCount.value = following.length;
      }
      loading.value = false;
    } catch (e) {
      loading.value = false;
      print('Error fetching following: $e');
    }
  }

  // Check if current user is following another user
  Future<bool> checkFollowStatus(String userId) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await SupabaseService.client
          .from('followers')
          .select()
          .eq('user_id', currentUser.id)
          .eq('following_id', userId);

      final isUserFollowing = (response as List).isNotEmpty;
      isFollowing.value = isUserFollowing;
      return isUserFollowing;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Follow a user
  Future<void> followUser(String userId) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;

      if (currentUser.id == userId) {
        showSnackBar('Error', 'You cannot follow yourself');
        return;
      }

      await SupabaseService.client.from('followers').insert({
        'user_id': currentUser.id,
        'following_id': userId,
      });

      isFollowing.value = true;
      await fetchFollowerCount(userId);
      showSnackBar('Success', 'Successfully followed user');
    } catch (e) {
      print('Error following user: $e');
      showSnackBar('Error', 'Failed to follow user');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;

      await SupabaseService.client
          .from('followers')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('following_id', userId);

      isFollowing.value = false;
      await fetchFollowerCount(userId);
      showSnackBar('Success', 'Successfully unfollowed user');
    } catch (e) {
      print('Error unfollowing user: $e');
      showSnackBar('Error', 'Failed to unfollow user');
    }
  }

  // Fetch follower count
  Future<int> fetchFollowerCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('followers')
          .select('id')
          .eq('following_id', userId);

      if (response != null) {
        final count = (response as List).length;
        followerCount.value = count;
        return count;
      }
      return 0;
    } catch (e) {
      print('Error fetching follower count: $e');
      return 0;
    }
  }

  // Fetch following count
  Future<void> fetchFollowingCount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('followers')
          .select()
          .eq('user_id', userId);
      
      if (response != null) {
        followingCount.value = (response as List).length;
      }
    } catch (e) {
      print('Error fetching following count: $e');
    }
  }
} 