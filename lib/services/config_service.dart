import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

class ConfigService extends GetxService {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseKey => dotenv.env['SUPABASE_KEY'] ?? '';
  static String get s3Bucket => dotenv.env['S3_BUCKET'] ?? '';

  Future<ConfigService> init() async {
    await initialize();
    return this;
  }

  static Future<void> initialize() async {
    try {
      // Try loading from root directory first
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        // If that fails, try loading from assets
        await dotenv.load(fileName: "assets/.env");
      }

      print('Loaded environment variables:'); // Debug print
      print('SUPABASE_URL: ${supabaseUrl.isNotEmpty ? "Found" : "Missing"}');
      print('SUPABASE_KEY: ${supabaseKey.isNotEmpty ? "Found" : "Missing"}');
      print('S3_BUCKET: ${s3Bucket.isNotEmpty ? "Found" : "Missing"}');

      _validateConfig();
    } catch (e) {
      print('Error loading .env file: $e');
      // Instead of throwing, set default values for development
      dotenv.env['SUPABASE_URL'] = 'supabaseUrl';
      dotenv.env['SUPABASE_KEY'] = '{supabaseKey';
      dotenv.env['S3_BUCKET'] = 's3Bucket';
      print('Using default configuration values');
    }
  }

  static void _validateConfig() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is not configured');
    }
    if (supabaseKey.isEmpty) {
      throw Exception('SUPABASE_KEY is not configured');
    }
    if (s3Bucket.isEmpty) {
      throw Exception('S3_BUCKET is not configured');
    }
  }
}