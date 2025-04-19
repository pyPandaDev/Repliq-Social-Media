import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:repliq/services/navigation_service.dart';

class Home extends StatelessWidget {
  Home({super.key});
  final NavigationService navigationService = Get.put(NavigationService());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on home page, navigate to home page
        if (navigationService.currentIndex.value != 0) {
          navigationService.updateIndex(0);
          return false; // Prevent default back behavior
        }
        // If on home page, show exit confirmation
        final shouldPop = await showDialog<bool>(
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
        return shouldPop ?? false;
      },
      child: Scaffold(
        bottomNavigationBar: Obx(
          () => NavigationBar(
            selectedIndex: navigationService.currentIndex.value,
            onDestinationSelected: (value) =>
                navigationService.updateIndex(value),
            animationDuration: const Duration(milliseconds: 500),
            destinations: <Widget>[
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/home.png',
                  height: 24,
                  color: Colors.grey,
                ),
                label: "home",
                selectedIcon: Image.asset(
                  'assets/images/home.png',
                  height: 24,
                  color: Colors.white,
                ),
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/search.png',
                  height: 24,
                  color: Colors.grey,
                ),
                label: "search",
                selectedIcon: Image.asset(
                  'assets/images/search.png',
                  height: 24,
                  color: Colors.white,
                ),
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/add.png',
                  height: 24,
                  color: Colors.grey,
                ),
                label: "add",
                selectedIcon: Image.asset(
                  'assets/images/add.png',
                  height: 24,
                  color: Colors.white,
                ),
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/chat.png',
                  height: 40,
                  color: Colors.grey,
                ),
                label: "AI Chat",
                selectedIcon: Image.asset(
                  'assets/images/chat.png',
                  height: 40,
                  color: Colors.white,
                ),
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/notification.png',
                  height: 24,
                  color: Colors.grey,
                ),
                label: "Notification",
                selectedIcon: Image.asset(
                  'assets/images/notification.png',
                  height: 24,
                  color: Colors.white,
                ),
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/images/profile.png',
                  height: 24,
                  color: Colors.grey,
                ),
                label: "Profile",
                selectedIcon: Image.asset(
                  'assets/images/profile.png',
                  height: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: Obx(() => AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.ease,
              switchOutCurve: Curves.easeInOut,
              child:
                  navigationService.pages()[navigationService.currentIndex.value],
            )),
      ),
    );
  }
}
