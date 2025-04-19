import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/search_user_controller.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/services/navigation_service.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/search_input.dart';
import 'package:repliq/widgets/search_user_tile.dart';
import 'package:repliq/routes/route_names.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  final TextEditingController textEditingController =
      TextEditingController(text: "");
  final SearchUserController controller = Get.put(SearchUserController());
  final FollowerController followerController = Get.put(FollowerController());

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Add listener to refresh following state when page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFollowingState();
    });
  }

  void _refreshFollowingState() async {
    // Refresh following state for all users in the search results
    for (var user in controller.users) {
      if (user != null) {
        await followerController.checkFollowStatus(user.id!);
      }
    }
  }

  void searchUser(String? name) async {
    if (name != null) {
      await controller.searchUser(name);
      // After search, refresh following state for new results
      _refreshFollowingState();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
              onPressed: () {
                Get.find<NavigationService>().backToPrevIndex();
              },
              icon: const Icon(Icons.close)),
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchInput(
              textController: textEditingController,
              hintText: "Search",
              callback: searchUser,
            ),
          ),
          Expanded(
            child: Obx(
              () => controller.loading.value
                  ? const Loading()
                  : Column(
                      children: [
                        if (controller.users.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: controller.users.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final user = controller.users[index];
                                if (user == null) return const SizedBox();
                                return GestureDetector(
                                  onTap: () async {
                                    // Check follow status before navigating
                                    await followerController.checkFollowStatus(user.id!);
                                    Get.toNamed(RouteNames.showProfile, arguments: user.id);
                                  },
                                  child: SearchUserTile(user: user),
                                );
                              },
                            ),
                          )
                        else if (controller.users.isEmpty &&
                            controller.notFound.value == true)
                          const Center(
                            child: Text(
                              "No user found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                "Search users with their names",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
