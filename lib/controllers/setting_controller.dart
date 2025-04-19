import 'package:get/get.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/storage/storage.dart';
import 'package:repliq/utils/storage/storage_key.dart';


class SettingController extends GetxController {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  
  // Notification toggles
  final likesNotification = true.obs;
  final repliesNotification = true.obs;
  final followersNotification = true.obs;

  void logout() async {
    Storage.session.remove(StorageKey.session);
    await SupabaseService.client.auth.signOut();
    Get.offAllNamed(RouteNames.login);
  }
}
