import 'dart:async';
import 'package:get/get.dart';
import 'package:repliq/models/user_model.dart';
import 'package:repliq/services/supabase_service.dart';


class SearchUserController extends GetxController {
  var loading = false.obs;
  var notFound = false.obs;
  RxList<UserModel?> users = RxList<UserModel?>();
  Timer? _debounce;

  Future<void> searchUser(String name) async {
    loading.value = true;
    notFound.value = false;
    users.clear(); // Clear previous results immediately
    
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (name.isEmpty) {
        loading.value = false;
        return;
      }

      try {
        final List<dynamic> data = await SupabaseService.client
            .from("users")
            .select("*")
            .ilike("metadata->>name", "%$name%");
            
        if (data.isNotEmpty) {
          users.value = [for (var item in data) UserModel.fromJson(item)];
          notFound.value = false;
        } else {
          users.clear();
          notFound.value = true;
        }
      } catch (e) {
        print('Search error: $e');
        users.clear();
        notFound.value = true;
      } finally {
        loading.value = false;
      }
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
