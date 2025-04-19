import 'package:get/get.dart';
import 'package:repliq/routes/route_names.dart';
import 'package:repliq/services/supabase_service.dart';
import 'package:repliq/utils/helper.dart';
import 'package:repliq/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final registerLoading = false.obs;
  final loginLoading = false.obs;

  // * Register Method
  Future<void> register(String name, String email, String password) async {
    try {
      registerLoading.value = true;
      final AuthResponse response = await SupabaseService.client.auth
          .signUp(email: email, password: password, data: {"name": name});
      
      if (response.user != null) {
        await StorageService.saveUserSession(response.session!.toJson());
        Get.offAllNamed(RouteNames.home);
      } else {
        showSnackBar("Error", "Something went wrong");
      }
    } catch (e) {
      showSnackBar("Error", "Registration failed: ${e.toString()}");
    } finally {
      registerLoading.value = false;
    }
  }

  // * Login user
  Future<void> login(String email, String password) async {
    try {
      loginLoading.value = true;
      final AuthResponse response = await SupabaseService.client.auth
          .signInWithPassword(email: email, password: password);
      
      if (response.user != null) {
        await StorageService.saveUserSession(response.session!.toJson());
        Get.offAllNamed(RouteNames.home);
      } else {
        showSnackBar("Error", "Invalid credentials");
      }
    } on AuthException catch (error) {
      showSnackBar("Error", error.message);
    } catch (error) {
      showSnackBar("Error", "Something went wrong. Please try again.");
    } finally {
      loginLoading.value = false;
    }
  }
}