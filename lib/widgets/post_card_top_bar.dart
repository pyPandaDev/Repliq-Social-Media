import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/models/post_model.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/utils/helper.dart';
import 'package:repliq/utils/type_def.dart';
import 'package:flutter/services.dart';
import 'package:repliq/controllers/saved_posts_controller.dart';

class PostCardTopBar extends StatelessWidget {
  final PostModel post;
  final bool isAuthPost;
  final DeleteCallback? callback;
  final SavedPostsController _savedPostsController = Get.put(SavedPostsController());
  
  PostCardTopBar({
    required this.post,
    this.isAuthPost = false,
    this.callback,
    super.key,
  });

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        side: BorderSide(color: Colors.grey[900]!, width: 0.5),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          border: Border(
            left: BorderSide(color: Colors.grey[900]!, width: 0.5),
            right: BorderSide(color: Colors.grey[900]!, width: 0.5),
            top: BorderSide(color: Colors.grey[900]!, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FutureBuilder<bool>(
              future: _savedPostsController.isPostSaved(int.parse(post.id!)),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error checking saved status: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                
                final isSaved = snapshot.data ?? false;
                return _buildOptionTile(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  title: isSaved ? 'Unsave' : 'Save',
                  onTap: () async {
                    try {
                      final saved = await _savedPostsController.savePost(int.parse(post.id!));
                      Navigator.pop(context);
                      _showSaveStatusMessage(saved);
                    } catch (e) {
                      print('Error saving post: $e');
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.not_interested,
              title: 'Not interested',
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionTile(
              icon: Icons.link,
              title: 'Copy link',
              onTap: () {
                final link = 'https://yourdomain.com/post/${post.id}';
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                Get.snackbar(
                  '',
                  'Link copied',
                  backgroundColor: Colors.grey[900]?.withOpacity(0.8),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.zero,
                  borderRadius: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.volume_off_outlined,
              title: 'Mute',
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionTile(
              icon: Icons.block,
              title: 'Block',
              onTap: () => Navigator.pop(context),
              isDestructive: true,
            ),
            _buildOptionTile(
              icon: Icons.flag_outlined,
              title: 'Report',
              onTap: () => Navigator.pop(context),
              isDestructive: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSaveStatusMessage(bool saved) {
    Get.snackbar(
      '',
      saved ? 'Post saved' : 'Post removed from saved items',
      backgroundColor: Colors.grey[900]?.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.zero,
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      titleText: const SizedBox.shrink(),
      messageText: Text(
        saved ? 'Post saved' : 'Post removed from saved items',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minLeadingWidth: 20,
      horizontalTitleGap: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              Get.toNamed(RouteNames.showProfile, arguments: post.userId),
          child: Text(
            post.user?.metadata?.name ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formateDateFromNow(post.createdAt?.toString() ?? '')),
            const SizedBox(width: 10),
            isAuthPost
                ? GestureDetector(
                    onTap: () {
                      confirmBox("Are you sure ?",
                          "Once it's deleted then you won't recover it.", () {
                        callback!(post.id!.toString());
                      });
                    },
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  )
                : GestureDetector(
                    onTap: () => _showPostOptions(context),
                    child: const Icon(Icons.more_horiz),
                  ),
          ],
        )
      ],
    );
  }
}