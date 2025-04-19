import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/thread_controller.dart';
import 'package:repliq/widgets/comment_card.dart';
import 'package:repliq/widgets/loading.dart';
import 'package:repliq/widgets/post_card.dart';

class ShowThread extends StatefulWidget {
  const ShowThread({super.key});

  @override
  State<ShowThread> createState() => _ShowThreadState();
}

class _ShowThreadState extends State<ShowThread> {
  final String postId = Get.arguments;
  final ThreadController controller = Get.put(ThreadController());

  @override
  void initState() {
    controller.show(postId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thread"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Obx(
          () => controller.showPostLoading.value
              ? const Loading()
              : Column(
                  children: [
                    PostCard(post: controller.post.value),

                    const SizedBox(height: 20),
                    // * load thread comments
                    if (controller.commentLoading.value)
                      const Loading()
                    else if (controller.comments.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.comments.length,
                        itemBuilder: (context, index) {
                          final comment = controller.comments[index];
                          if (comment == null) return const SizedBox();
                          return CommentCard(comment: comment);
                        },
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "No replies yet",
                            style: TextStyle(color: Colors.grey),
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
