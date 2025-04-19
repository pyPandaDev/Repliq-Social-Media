import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/follower_controller.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/loading.dart';

class Following extends StatelessWidget {
  const Following({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetX<FollowerController>(
        builder: (controller) {
          if (controller.loading.value) {
            return const Loading();
          }

          if (controller.following.isEmpty) {
            return const Center(
              child: Text(
                'Not following anyone yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.following.length,
            itemBuilder: (context, index) {
              final following = controller.following[index].following;
              if (following == null) return const SizedBox();
              
              return ListTile(
                leading: CircleImage(
                  url: following.metadata?.image,
                  radius: 25,
                ),
                title: Text(
                  following.metadata?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('@${following.metadata?.name ?? 'unknown'}'),
                onTap: () => Get.toNamed(
                  RouteNames.showProfile,
                  arguments: following.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 