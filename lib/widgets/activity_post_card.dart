import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/post_image.dart';

class ActivityPostCard extends StatelessWidget {
  final PostModel post;
  final String activityType;
  final String? replyText;

  const ActivityPostCard({
    required this.post,
    required this.activityType,
    this.replyText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: context.width * 0.12,
              child: Column(
                children: [
                  CircleImage(url: post.user?.metadata?.image),
                  if (activityType == 'reply')
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[800],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: context.width * 0.80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.user?.metadata?.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        activityType == 'reply' ? 'Replied' : 'Liked',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (replyText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      replyText!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(post.content!),
                  if (post.image != null) ...[
                    const SizedBox(height: 10),
                    PostImage(postId: post.id!, url: post.image!),
                  ],
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xff242424)),
      ],
    );
  }
} 