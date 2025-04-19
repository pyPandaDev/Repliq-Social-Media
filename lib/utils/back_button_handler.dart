import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/routes/route_names.dart';

class BackButtonHandler {
  static Future<bool> handleBackButton(BuildContext context) async {
    final currentRoute = Get.currentRoute;
    
    // Handle profile view navigation
    if (currentRoute == RouteNames.showProfile) {
      Get.back();
      return false;
    }
    
    // If we're not on the home page, navigate to home
    if (currentRoute != RouteNames.home) {
      Get.until((route) => route.settings.name == RouteNames.home);
      return false;
    }
    
    // If we're on the home page, show a dialog to confirm exit
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    
    return shouldExit ?? false;
  }
} 