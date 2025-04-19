import 'package:get/get.dart';
import 'package:repliq/controllers/follower_controller.dart';

class FollowersBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FollowerController());
  }
} 