import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/profile_controller.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/sliver_appbar_delete.dart';
import 'package:repliq/utils/style/button_styles.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/comment_card.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/post_card.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/widgets/expandable_bio.dart';
import 'package:repliq/views/profile/profile_image_view.dart';
import 'package:repliq/utils/helper.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final ProfileController controller = Get.put(ProfileController());
  final FollowerController followerController = Get.put(FollowerController());

  @override
  void initState() {
    if (supabaseService.currentUser.value?.id != null) {
      final userId = supabaseService.currentUser.value!.id;
      controller.fetchPosts(userId);
      controller.fetchComments(userId);
      followerController.fetchFollowers(userId);
      followerController.fetchFollowing(userId);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.language),
        centerTitle: false,
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
                expandedHeight: 140,
                collapsedHeight: 140,
                automaticallyImplyLeading: false,
                pinned: true,
                flexibleSpace: Padding(
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
                              () => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    supabaseService.currentUser.value?.userMetadata?["name"] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                    ),
                                  ),
                                  if ((supabaseService.currentUser.value?.userMetadata?["description"] ?? "").isNotEmpty) ...[
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: context.width * 0.60,
                                      ),
                                      child: ExpandableBio(
                                        text: supabaseService.currentUser.value?.userMetadata?["description"] ?? "",
                                        style: const TextStyle(color: Colors.grey),
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  GetX<FollowerController>(
                                    init: FollowerController(),
                                    builder: (controller) => GestureDetector(
                                      onTap: () => Get.toNamed(
                                        RouteNames.followers,
                                        arguments: supabaseService.currentUser.value?.id,
                                      ),
                                      child: Text(
                                        "${controller.followerCount} followers",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Obx(
                            () => GestureDetector(
                              onTap: () {
                                final rawImageUrl = supabaseService.currentUser.value?.userMetadata?["image"] ?? '';
                                if (rawImageUrl.isNotEmpty) {
                                  final imageUrl = getS3Url(rawImageUrl);
                                  final userName = supabaseService.currentUser.value?.userMetadata?["name"] ?? 'Unknown';
                                  Get.to(() => ProfileImageView(
                                    imageUrl: imageUrl,
                                    userName: userName,
                                  ));
                                }
                              },
                              child: Hero(
                                tag: 'profile-image',
                                child: CircleImage(
                                  url: supabaseService.currentUser.value?.userMetadata?["image"] ?? '',
                                  radius: 40,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Get.toNamed(RouteNames.editProfile);
                              },
                              style: customOutlineStyle(),
                              child: const Text("Edit profile"),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: customOutlineStyle(),
                              child: const Text("Share profile"),
                            ),
                          ),
                        ],
                      ),
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
                        const Loading()
                      else if (controller.posts.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: controller.posts.length,
                          itemBuilder: (context, index) => PostCard(
                            post: controller.posts[index],
                            isAuthPost: true,
                            callback: controller.deleteThread,
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
                                  comment: controller.comments[index]!,
                                  isAuthCard: true,
                                  callback: (id) => controller.deleteReply(int.parse(id)),
                                ),
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
    );
  }
}


