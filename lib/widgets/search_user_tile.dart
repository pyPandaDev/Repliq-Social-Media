import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/models/user_model.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/widgets/circle_image.dart';

class SearchUserTile extends StatelessWidget {
  final UserModel user;
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final FollowerController followerController = Get.find<FollowerController>();

  SearchUserTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = user.id == supabaseService.currentUser.value?.id;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            horizontalTitleGap: 12,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleImage(
              url: user.metadata?.image,
              radius: 20,
            ),
            title: Text(
              user.metadata?.name ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: FutureBuilder<int>(
              future: followerController.fetchFollowerCount(user.id ?? ''),
              builder: (context, snapshot) {
                return Text(
                  '${snapshot.data ?? 0} followers',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            trailing: isCurrentUser 
                ? null
                : Obx(() {
                    bool isFollowing = followerController.following
                        .any((item) => item.followingId == user.id);

                    return SizedBox(
                      width: 85,
                      height: 32,
                      child: TextButton(
                        onPressed: () async {
                          if (user.id != null) {
                            try {
                              if (isFollowing) {
                                await followerController.unfollowUser(user.id!);
                              } else {
                                await followerController.followUser(user.id!);
                              }
                              await followerController.fetchFollowing(
                                supabaseService.currentUser.value?.id ?? ''
                              );
                            } catch (e) {
                              print('Error updating follow status: $e');
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.transparent : Colors.white,
                          side: isFollowing ? const BorderSide(color: Colors.white) : null,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: const Size(85, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: isFollowing ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
            onTap: () {
              if (isCurrentUser) {
                Get.toNamed(RouteNames.showProfile, arguments: supabaseService.currentUser.value?.id);
              } else {
                Get.toNamed(RouteNames.showProfile, arguments: user.id);
              }
            },
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey,
        ),
      ],
    );
  }
} 