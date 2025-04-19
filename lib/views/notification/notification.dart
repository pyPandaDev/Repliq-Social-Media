import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/notification_controller.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/navigation_service.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/helper.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/loading.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  final NotificationController controller = Get.put(NotificationController());

  @override
  void initState() {
    controller.fetchNotifications(supabaseService.currentUser.value!.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Get.find<NavigationService>().backToPrevIndex();
              },
              icon: const Icon(Icons.close)),
          title: const Text("Notification"),
        ),
        body: SingleChildScrollView(
          child: Obx(() => controller.loading.value
              ? const Loading()
              : Column(
                  children: [
                    if (controller.notifications.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.notifications.length,
                        itemBuilder: (context, index) => ListTile(
                          onTap: () {
                            Get.toNamed(RouteNames.showThread,
                                arguments:
                                    controller.notifications[index]!.postId!.toString());
                          },
                          titleAlignment: ListTileTitleAlignment.top,
                          isThreeLine: true,
                          leading: CircleImage(
                            url: controller
                                .notifications[index]!.user!.metadata?.image,
                          ),
                          title: Text(controller
                              .notifications[index]!.user!.metadata!.name!),
                          trailing: Text(formateDateFromNow(
                              controller.notifications[index]!.createdAt!)),
                          subtitle: Text(
                              controller.notifications[index]!.notification!),
                        ),
                      )
                    else
                      const Text("No notifications found"),
                  ],
                )),
        ));
  }
}
