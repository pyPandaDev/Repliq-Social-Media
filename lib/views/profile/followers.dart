import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/loading.dart';

class Followers extends StatelessWidget {
  const Followers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetX<FollowerController>(
        builder: (controller) {
          if (controller.loading.value) {
            return const Loading();
          }

          if (controller.followers.isEmpty) {
            return const Center(
              child: Text(
                'No followers yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.followers.length,
            itemBuilder: (context, index) {
              final follower = controller.followers[index].following;
              if (follower == null) return const SizedBox();
              
              return ListTile(
                leading: CircleImage(
                  url: follower.metadata?.image,
                  radius: 25,
                ),
                title: Text(
                  follower.metadata?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('@${follower.metadata?.name ?? 'unknown'}'),
                onTap: () => Get.toNamed(
                  RouteNames.showProfile,
                  arguments: follower.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 