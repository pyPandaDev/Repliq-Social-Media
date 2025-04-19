import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/voice_service.dart';

class VoiceButton extends StatelessWidget {
  final String text;
  final String messageId;
  
  const VoiceButton({
    Key? key,
    required this.text,
    required this.messageId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final voiceService = VoiceService.instance;
      final isThisMessageSpeaking = voiceService.isSpeaking.value && 
                                  voiceService.currentMessageId.value == messageId;
      final isInitialized = voiceService.isInitialized.value;
      
      if (!isInitialized) {
        return IconButton(
          onPressed: () {
            Get.snackbar(
              'Initializing',
              'Please wait while voice service initializes...',
              backgroundColor: Colors.grey[900],
              colorText: Colors.white,
              duration: Duration(seconds: 2),
            );
          },
          icon: Icon(
            Icons.volume_off,
            color: Colors.grey[600],
            size: 16,
          ),
          padding: EdgeInsets.zero,
          tooltip: 'Voice not ready',
        );
      }

      return IconButton(
        onPressed: () {
          try {
            voiceService.speak(text, messageId);
          } catch (e) {
            print('Error in voice button: $e');
            Get.snackbar(
              'Error',
              'Failed to start voice playback',
              backgroundColor: Colors.grey[900],
              colorText: Colors.white,
              duration: Duration(seconds: 2),
            );
          }
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isThisMessageSpeaking ? Icons.stop_circle : Icons.volume_up,
            key: ValueKey<bool>(isThisMessageSpeaking),
            color: isThisMessageSpeaking ? Colors.red : Colors.grey[400],
            size: 16,
          ),
        ),
        padding: EdgeInsets.zero,
        tooltip: isThisMessageSpeaking ? 'Stop Speaking' : 'Read Aloud',
      );
    });
  }
} 