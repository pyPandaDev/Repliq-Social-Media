import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/replies_setting_controller.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/activity_post_card.dart';

class RepliesSetting extends StatelessWidget {
  const RepliesSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Replies'),
      ),
      body: GetX<RepliesSettingController>(
        init: RepliesSettingController()..loadReplies(),
        builder: (controller) {
          if (controller.loading.value) {
            return const Loading();
          }
          
          if (controller.replies.isEmpty) {
            return const Center(
              child: Text(
                'No replies yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.replies.length,
            itemBuilder: (context, index) {
              final reply = controller.replies[index];
              return ActivityPostCard(
                post: reply.post!,
                activityType: 'reply',
                replyText: reply.reply,
              );
            },
          );
        },
      ),
    );
  }
} 