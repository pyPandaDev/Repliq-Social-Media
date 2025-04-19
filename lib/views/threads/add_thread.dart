import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/controllers/thread_controller.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/widgets/add_thread_appbar.dart';
import 'package:repliq/widgets/circle_image.dart';
import 'package:repliq/widgets/thread_image_preview.dart';

class AddThread extends StatelessWidget {
  AddThread({super.key});
  final ThreadController controller = Get.put(ThreadController());
  final SupabaseService supabaseService = Get.find<SupabaseService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
               AddThreadAppBar(),
              const SizedBox(height: 5  ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => CircleImage(
                        url: supabaseService
                        .currentUser.value!.userMetadata?[ "image"],
                    )
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: context.width - 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => Text(
                              supabaseService
                                  .currentUser.value!.userMetadata?["name"],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextField(
                            autofocus: true,
                            controller: controller.contentController,
                            onChanged: (value) =>
                                controller.content.value = value,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 10,
                            minLines: 1,
                            maxLength: 1000,
                            decoration: const InputDecoration(
                              hintText: 'type a message',
                              border: InputBorder.none, // Remove border
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.pickImage();
                            },
                            child: const Icon(Icons.attach_file),
                          ),
                          // * If user select image then show preview
                          Obx(
                            () => Column(
                              children: [
                                if (controller.image.value != null)
                                  ThreadImagePreview()
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
