import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/models/user_model.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/utils/helper.dart';
import 'package:repliq/widgets/circle_image.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  const UserTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: CircleImage(url: user.metadata?.image),
      ),
      title: Text(user.metadata?.name ?? 'Unknown'),
      titleAlignment: ListTileTitleAlignment.top,
      trailing: OutlinedButton(
        onPressed: () {
          if (user.id != null) {
            Get.toNamed(RouteNames.showProfile, arguments: user.id);
          }
        },
        child: const Text("View profile"),
      ),
      subtitle: user.createdAt != null 
          ? Text(formateDateFromNow(user.createdAt!))
          : null,
    );
  }
}
