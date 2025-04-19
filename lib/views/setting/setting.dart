import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/utils/helper.dart';
import 'package:repliq/views/setting/saved_posts.dart';

class Setting extends StatelessWidget {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final FollowerController followerController = Get.find<FollowerController>();

  Setting({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Get.previousRoute == RouteNames.profile) {
          Get.until((route) => route.settings.name == RouteNames.home);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
              const SizedBox(height: 20),
            // Profile Section
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Profile Picture
                    Obx(() => CircleImage(
                      url: supabaseService.currentUser.value?.userMetadata?["image"],
                      radius: 50,
                    )),
                    const SizedBox(height: 16),
                    // Name
                    Obx(() => Text(
                      supabaseService.currentUser.value?.userMetadata?["name"] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )),
                    const SizedBox(height: 20),
                    // Followers and Following
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (supabaseService.currentUser.value?.id != null) {
                              Get.toNamed(
                                RouteNames.followers,
                                arguments: supabaseService.currentUser.value!.id,
                              );
                            }
                          },
                          child: Column(
                            children: [
                              Obx(() => Text(
                                '${followerController.followerCount}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )),
                              const Text(
                                'Followers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: () {
                            if (supabaseService.currentUser.value?.id != null) {
                              Get.toNamed(
                                RouteNames.followers,
                                arguments: supabaseService.currentUser.value!.id,
                              );
                            }
                          },
                          child: Column(
                            children: [
                              Obx(() => Text(
                                '${followerController.followingCount}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )),
                              const Text(
                                'Following',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Menu Items
              _buildMenuItem(
                'Profile Settings',
                Icons.person_outline,
                () => Get.toNamed(RouteNames.editProfile),
              ),
              _buildMenuItem(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                () {
                  // Handle privacy policy
                },
              ),
              _buildMenuItem(
                'About',
                Icons.info_outline,
                () {
                  // Handle about
                },
              ),
              _buildMenuItem(
                'Contact Us',
                Icons.mail_outline,
                () => Get.toNamed(RouteNames.contactUs),
              ),
              ListTile(
                onTap: () => Get.to(() => const SavedPosts()),
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Saved Posts'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 20),
              // Logout Button
              _buildMenuItem(
                'Logout',
                Icons.logout,
                () {
                  confirmBox(
                    "Are you sure?",
                    "Do you want to logout?",
                    () async {
                      await SupabaseService.client.auth.signOut();
                      Get.offAllNamed(RouteNames.login);
                    },
                  );
                },
                isDestructive: true,
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
