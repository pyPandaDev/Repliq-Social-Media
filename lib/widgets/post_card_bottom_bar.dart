import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/thread_controller.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/widgets/share_button.dart';

class PostCardBottombar extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onCommentAdded;
  const PostCardBottombar({
    required this.post,
    this.onCommentAdded,
    super.key,
  });

  @override
  State<PostCardBottombar> createState() => _PostCardBottombarState();
}

class _PostCardBottombarState extends State<PostCardBottombar> {
  final ThreadController controller = Get.find<ThreadController>();
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  String likeStatus = "";

  void likeDislike(String status) async {
    setState(() {
      likeStatus = status;
    });
    if (likeStatus == "0") {
      widget.post.likes = [];
    }
    final currentUser = supabaseService.currentUser.value;
    if (currentUser != null && widget.post.id != null && widget.post.userId != null) {
      await controller.likeDislike(
        status, 
        widget.post.id!, 
        widget.post.userId!, 
        currentUser.id
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icons row
        Row(
          children: [
            IconButton(
              onPressed: () {
                likeStatus == "1" || (widget.post.likes != null && widget.post.likes!.isNotEmpty)
                    ? likeDislike("0")
                    : likeDislike("1");
              },
              icon: Image.asset(
                'assets/images/like.png',
                width: 24,
                height: 24,
                color: likeStatus == "1" || (widget.post.likes != null && widget.post.likes!.isNotEmpty)
                    ? Colors.red[700]
                    : Colors.white,
              ),
            ),
            IconButton(
              onPressed: () async {
                if (widget.post.id != null) {
                  await Get.toNamed(RouteNames.addComment, arguments: widget.post);
                  if (widget.onCommentAdded != null) {
                    widget.onCommentAdded!();
                  }
                }
              },
              icon: Image.asset(
                'assets/images/comment.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
            ),
            ShareButton(
              postId: widget.post.id ?? '',
              imagePath: widget.post.image,
            ),
          ],
        ),
        // Counts row - reordered to match icons above
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Text(
                "${widget.post.likeCount ?? 0} likes",
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                "${widget.post.commentCount ?? 0} replies",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        )
      ],
    );
  }
}