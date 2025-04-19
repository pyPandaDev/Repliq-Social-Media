import 'package:get/get.dart';
import 'package:repliq/controllers/profile_controller.dart';
import 'package:repliq/controllers/follower_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<FollowerController>(() => FollowerController());
  }
} 