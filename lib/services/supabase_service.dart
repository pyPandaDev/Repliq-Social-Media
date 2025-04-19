import 'package:get/get.dart';
import 'package:social_media/utils/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService{
 @override
  void onInit() async {
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
    super.onInit();
  }
  static final SupabaseClient client = Supabase.instance.client;
} 