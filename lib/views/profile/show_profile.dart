import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/profile_controller.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/utils/sliver_appbar_delete.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/comment_card.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/post_card.dart';
import 'package:repliq/widgets/expandable_bio.dart';

class ShowProfile extends StatefulWidget {
  const ShowProfile({super.key});

  @override
  State<ShowProfile> createState() => _ProfileState();
}

class _ProfileState extends State<ShowProfile> {
  final String userId = Get.arguments;
  final ProfileController controller = Get.find<ProfileController>();
  final FollowerController followerController = Get.find<FollowerController>();
  final SupabaseService supabaseService = Get.find<SupabaseService>();

  bool get isCurrentUser => userId == supabaseService.currentUser.value?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize the profile data after the frame is built
      await _initializeProfile();
    });
  }

  Future<void> _initializeProfile() async {
    try {
      // Clear existing data
      controller.posts.clear();
      controller.comments.clear();
      
      // Initialize the profile data
      await controller.getUser(userId);
      await followerController.fetchFollowers(userId);
      await followerController.fetchFollowing(userId);
      await followerController.checkFollowStatus(userId);
      await followerController.fetchFollowerCount(userId);
    } catch (e) {
      print('Error initializing profile: $e');
    }
  }

  @override
  void dispose() {
    // Clear data when disposing
    controller.posts.clear();
    controller.comments.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Get.previousRoute == RouteNames.setting) {
          Get.until((route) => route.settings.name == RouteNames.home);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (Get.previousRoute == RouteNames.setting) {
                Get.until((route) => route.settings.name == RouteNames.home);
              } else {
                Get.back();
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
                onPressed: () => Get.toNamed(RouteNames.setting),
                icon: const Icon(Icons.sort))
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: 160,
                  collapsedHeight: 160,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Obx(
                                      () => controller.userLoading.value
                                          ? const Loading()
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  controller.user.value?.metadata?.name ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 25,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (controller.user.value?.metadata?.description != null)
                                                  ExpandableBio(
                                                    text: controller.user.value!.metadata!.description!,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                // Followers count
                                                GestureDetector(
                                                  onTap: () => Get.toNamed(
                                                    RouteNames.followers,
                                                    arguments: userId,
                                                  ),
                                                  child: Obx(() => Text(
                                                    "${followerController.followerCount} followers",
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  )),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Obx(
                                    () => CircleImage(
                                      url: controller.user.value?.metadata?.image ?? '',
                                      radius: 35,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Follow button - only show for other users
                              if (!isCurrentUser)
                                Obx(() => SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (followerController.isFollowing.value) {
                                        followerController.unfollowUser(userId);
                                      } else {
                                        followerController.followUser(userId);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: followerController.isFollowing.value 
                                          ? Colors.transparent
                                          : Colors.white,
                                      foregroundColor: followerController.isFollowing.value 
                                          ? Colors.white
                                          : Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size.fromHeight(36),
                                      side: BorderSide(
                                        color: followerController.isFollowing.value 
                                            ? Colors.grey[400]!
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                      elevation: 0, // Remove shadow
                                    ),
                                    child: Text(
                                      followerController.isFollowing.value ? 'Following' : 'Follow',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: followerController.isFollowing.value 
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                )),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  floating: true,
                  pinned: true,
                  delegate: SliverAppBarDelegate(
                    const TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: 'Post'),
                        Tab(text: 'Replies'),
                      ],
                    ),
                  ),
                )
              ];
            },
            body: TabBarView(
              children: [
                Obx(
                  () => SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        if (controller.postLoading.value)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (controller.posts.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: controller.posts.length,
                            itemBuilder: (context, index) => PostCard(
                              post: controller.posts[index],
                              callback: (postId) async {
                                // Refresh the profile data after adding a comment
                                await _initializeProfile();
                                return;
                              },
                            ),
                          )
                        else
                          const Center(
                            child: Text("No Post found"),
                          )
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Obx(
                    () => controller.replyLoading.value
                        ? const Loading()
                        : Column(
                            children: [
                              const SizedBox(height: 10),
                              if (controller.comments.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: controller.comments.length,
                                  itemBuilder: (context, index) => CommentCard(
                                      comment: controller.comments[index]!),
                                )
                              else
                                const Center(
                                  child: Text("No reply found"),
                                )
                            ],
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
