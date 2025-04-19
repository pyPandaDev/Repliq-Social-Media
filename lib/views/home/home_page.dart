import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/home_controller.dart';
import 'package:repliq/widgets/post_card.dart';
import 'package:repliq/widgets/post_loading.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when back button is pressed
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: RefreshIndicator(
            onRefresh: () => controller.fetchPosts(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.asset(
                      "assets/images/logo.png",
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: false, // Remove back button
                ),
                SliverToBoxAdapter(
                  child: Obx(
                    () => controller.loading.value
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 5, // Show 5 loading cards
                            itemBuilder: (context, index) => const PostLoadingCard(),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemCount: controller.posts.length,
                            itemBuilder: (context, index) =>
                                PostCard(post: controller.posts[index]),
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