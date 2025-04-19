import 'package:get/get.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/views/setting/saved_posts.dart';

class AppRoutes {
  static final pages = [
    // ... existing routes ...
    GetPage(
      name: RouteNames.savedPosts,
      page: () => const SavedPosts(),
    ),
    // ... existing routes ...
  ];
} 