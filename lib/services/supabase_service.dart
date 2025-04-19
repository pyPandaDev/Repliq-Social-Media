import 'package:get/get.dart';
import 'package:repliq/services/config_service.dart';
import 'package:repliq/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService {
  Rx<User?> currentUser = Rx<User?>(null);
  RxBool isInitialized = false.obs;
  RxString errorMessage = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      await Supabase.initialize(
        url: ConfigService.supabaseUrl, 
        anonKey: ConfigService.supabaseKey,
      );

      // Check for current session
      currentUser.value = client.auth.currentUser;
      
      // If we have a current user, save their session
      if (currentUser.value != null) {
        final session = client.auth.currentSession;
        if (session != null) {
          await StorageService.saveUserSession({
            'user': currentUser.value?.toJson(),
            'session': session.toJson(),
          });
        }
      }

      listenAuthChange();
      isInitialized.value = true;
    } catch (e) {
      errorMessage.value = 'Failed to initialize Supabase: $e';
      print(errorMessage.value);
    }
  }

  // * Create Single Instance
  static final SupabaseClient client = Supabase.instance.client;

  // * first load the status
  Future<void> updateUserfromSession() async {
    try {
      if (StorageService.userSession != null) {
        var session = Session.fromJson(StorageService.userSession!);
        currentUser.value = session?.user;
      }
    } catch (e) {
      print('Failed to update user from session: $e');
      await StorageService.clearUserSession();
    }
  }

  // * listen auth changes
  void listenAuthChange() {
    client.auth.onAuthStateChange.listen(
      (data) async {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.userUpdated || 
            event == AuthChangeEvent.signedIn) {
          currentUser.value = data.session?.user;
          if (data.session != null) {
            await StorageService.saveUserSession({
              'user': data.session!.user?.toJson(),
              'session': data.session!.toJson(),
            });
          }
        } else if (event == AuthChangeEvent.signedOut) {
          currentUser.value = null;
          await StorageService.clearUserSession();
        }
      },
      onError: (error) {
        print('Auth state change error: $error');
        errorMessage.value = 'Authentication error: $error';
      },
    );
  }
}