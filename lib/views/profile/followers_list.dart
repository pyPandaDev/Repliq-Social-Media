import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/search_input.dart';
import 'package:repliq/services/supabase_service.dart';

class FollowersList extends StatefulWidget {
  final String userId;
  final bool isFollowers;

  const FollowersList({
    required this.userId,
    this.isFollowers = true,
    super.key,
  });

  @override
  State<FollowersList> createState() => _FollowersListState();
}

class _FollowersListState extends State<FollowersList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowerController followerController = Get.find<FollowerController>();
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxList<dynamic> filteredList = <dynamic>[].obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _updateFilteredList();
    }
  }

  Future<void> _loadData() async {
    await followerController.fetchFollowers(widget.userId);
    await followerController.fetchFollowing(widget.userId);
    _updateFilteredList();
  }

  void _updateFilteredList() {
    final list = _tabController.index == 0 
        ? followerController.followers 
        : followerController.following;

    if (searchQuery.isEmpty) {
      filteredList.value = list;
    } else {
      filteredList.value = list.where((item) {
        final user = _tabController.index == 0 ? item.follower : item.following;
        final name = user?.metadata?.name?.toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();
        return name.contains(query);
      }).toList();
    }
  }

  Widget _buildFollowButton(dynamic user) {
    if (user?.id == supabaseService.currentUser.value?.id) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      bool isFollowing = false;
      if (user?.id != null) {
        isFollowing = followerController.following.any((item) => 
          item.followingId == user?.id
        );
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 100,
          minHeight: 28,
          maxHeight: 28,
        ),
        child: OutlinedButton(
          onPressed: () async {
            if (user?.id != null) {
              try {
                if (isFollowing) {
                  await followerController.unfollowUser(user!.id);
                } else {
                  await followerController.followUser(user!.id);
                }
                await _loadData();
              } catch (e) {
                print('Error updating follow status: $e');
              }
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.black : Colors.transparent,
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              color: isFollowing ? Colors.white : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _tabController.index == 0 ? 'Followers' : 'Following',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 48, // Fixed height for the TabBar container
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                _updateFilteredList();
              },
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              indicatorPadding: EdgeInsets.zero,
              tabs: [
                SizedBox(
                  height: 44,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() => Text(
                        '${followerController.followerCount.value}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      const Text(
                        'Followers',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() => Text(
                        '${followerController.followingCount.value}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      const Text(
                        'Following',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchInput(
              textController: searchController,
              hintText: 'Search',
              callback: (query) {
                searchQuery.value = query ?? '';
                _updateFilteredList();
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (followerController.loading.value) {
                return const Loading();
              }

              if (filteredList.isEmpty) {
                return Center(
                  child: Text(
                    searchQuery.isEmpty
                        ? 'No ${_tabController.index == 0 ? 'followers' : 'following'} yet'
                        : 'No results found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filteredList.length,
                separatorBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(height: 1, color: Colors.grey),
                ),
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  final user = _tabController.index == 0 ? item.follower : item.following;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (user?.id != null) {
                                if (user?.id == supabaseService.currentUser.value?.id) {
                                  Get.back();
                                  return;
                                }
                                
                                Get.toNamed(
                                  RouteNames.showProfile,
                                  arguments: user!.id,
                                  preventDuplicates: true,
                                )?.then((_) {
                                  _loadData();
                                });
                              }
                            },
                            child: Row(
                              children: [
                                CircleImage(
                                  url: user?.metadata?.image,
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.metadata?.name ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (user?.metadata?.description != null)
                                        Text(
                                          user!.metadata!.description!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user?.id != supabaseService.currentUser.value?.id)
                          _buildFollowButton(user!),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
} 