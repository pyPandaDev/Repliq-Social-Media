import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math' show min;

class VoiceService extends GetxService {
  static VoiceService get instance => Get.find<VoiceService>();
  
  final FlutterTts _flutterTts = FlutterTts();
  final RxBool isSpeaking = false.obs;
  final RxBool isPaused = false.obs;
  final RxString currentMessageId = ''.obs;
  final RxBool isInitialized = false.obs;
  final RxString currentLanguage = "en-US".obs;
  String? _lastSpokenText;
  
  @override
  void onInit() {
    super.onInit();
    print('VoiceService onInit called');
    Future.delayed(const Duration(milliseconds: 100), initializeTts);
  }

  Future<bool> initializeTts() async {
    print('Starting TTS initialization...');
    try {
      // Basic configuration first
      print('Configuring TTS settings...');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Get available languages
      print('Getting available languages...');
      try {
        final languages = await _flutterTts.getLanguages;
        print('Available languages: $languages');
        
        // Check if Hindi is available
        if (languages.contains('hi-IN')) {
          print('Hindi TTS is available');
        }
      } catch (e) {
        print('Error getting languages: $e');
      }
      
      // Set handlers
      print('Setting up TTS handlers...');
      _flutterTts.setStartHandler(() {
        print('TTS Start Handler called');
        isSpeaking.value = true;
        isPaused.value = false;
      });
      
      _flutterTts.setCompletionHandler(() {
        print('TTS Completion Handler called');
        isSpeaking.value = false;
        isPaused.value = false;
      });
      
      _flutterTts.setErrorHandler((msg) {
        print('TTS Error Handler called: $msg');
        isSpeaking.value = false;
        isPaused.value = false;
      });
      
      _flutterTts.setPauseHandler(() {
        print('TTS Paused');
        isPaused.value = true;
      });
      
      _flutterTts.setContinueHandler(() {
        print('TTS Continued');
        isPaused.value = false;
      });

      // Set initial language
      print('Setting TTS language...');
      await _flutterTts.setLanguage(currentLanguage.value);
      
      // Test TTS with a simple message
      print('Testing TTS with a simple message...');
      final result = await _flutterTts.speak("Test");
      print('TTS speak test result: $result');
      
      if (result == 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.stop();
        isInitialized.value = true;
        print('TTS initialized successfully');
        return true;
      } else {
        throw Exception('TTS initialization failed with result: $result');
      }
    } catch (e) {
      print('Error initializing TTS: $e');
      isInitialized.value = false;
      return false;
    }
  }

  Future<void> togglePlayPause(String text, String messageId) async {
    print('Toggle Play/Pause - Speaking: ${isSpeaking.value}, Paused: ${isPaused.value}');
    
    if (isSpeaking.value || isPaused.value) {
      if (isPaused.value) {
        if (_lastSpokenText != null) {
          await speak(_lastSpokenText!, messageId);
        }
      } else {
        await stop();
        isPaused.value = true;
        print('Speech paused');
      }
    } else {
      _lastSpokenText = text;
      await speak(text, messageId);
    }
  }

  Future<void> setLanguage(String text) async {
    // Detect if text contains Hindi characters (Devanagari)
    final containsHindi = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    
    // Detect Hinglish using common Hinglish patterns
    final containsHinglish = RegExp(
      r'\b(namaste|kya|hai|nahi|acha|theek|bohot|bahut|matlab|samajh|kaise|kaun|kahan|yahan|wahan|aap|tum|main|hum|mera|tera|uska|hamara|karna|jana|aana|khana|peena|sona|jagna|dena|lena|milna|bolna|sunna|dekhna|samajhna)\b',
      caseSensitive: false
    ).hasMatch(text);
    
    String newLanguage;
    if (containsHindi) {
      newLanguage = 'hi-IN';
    } else if (containsHinglish) {
      // For Hinglish, we'll use Hindi TTS for better pronunciation
      newLanguage = 'hi-IN';
      print('Detected Hinglish text, using Hindi TTS');
    } else {
      newLanguage = 'en-US';
    }
    
    if (currentLanguage.value != newLanguage) {
      try {
        // Configure voice settings for better Hindi pronunciation
        if (newLanguage == 'hi-IN') {
          await _flutterTts.setSpeechRate(0.4); // Slower rate for Hindi
          await _flutterTts.setPitch(1.0);
        } else {
          await _flutterTts.setSpeechRate(0.5); // Default rate for English
          await _flutterTts.setPitch(1.0);
        }
        
        await _flutterTts.setLanguage(newLanguage);
        currentLanguage.value = newLanguage;
        print('Language set to: $newLanguage');
      } catch (e) {
        print('Error setting language: $e');
        // Fallback to English if Hindi fails
        if (newLanguage == 'hi-IN') {
          try {
            await _flutterTts.setLanguage('en-US');
            currentLanguage.value = 'en-US';
            print('Fallback to English due to error');
          } catch (e) {
            print('Error setting fallback language: $e');
          }
        }
      }
    }
  }

  Future<void> speak(String text, String messageId) async {
    if (!isInitialized.value) {
      print('TTS not initialized, attempting to reinitialize...');
      final initialized = await initializeTts();
      if (!initialized) {
        print('Reinitialization failed');
        return;
      }
    }
    
    try {
      // Stop any ongoing speech
      if (isSpeaking.value && !isPaused.value) {
        print('Stopping ongoing speech before starting new one');
        await stop();
      }
      
      // Clean the text before language detection
      text = _cleanTextForSpeech(text);
      _lastSpokenText = text;
      
      // Set appropriate language based on text content
      await setLanguage(text);
      
      final previewLength = min(50, text.length);
      print('Speaking text (${currentLanguage.value}): ${text.substring(0, previewLength)}...');
      
      isSpeaking.value = true;
      isPaused.value = false;
      currentMessageId.value = messageId;
      
      final result = await _flutterTts.speak(text);
      print('TTS speak result: $result');
      
      if (result != 1) {
        throw Exception('Failed to speak text: result=$result');
      }
    } catch (e) {
      print('Error speaking text: $e');
      isSpeaking.value = false;
      isPaused.value = false;
      currentMessageId.value = '';
    }
  }

  String _cleanTextForSpeech(String text) {
    print('Cleaning text for speech...');
    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), 'Code block omitted.');
    
    // Remove inline code
    text = text.replaceAll(RegExp(r'`[^`]*`'), '');
    
    // Remove markdown links - keep only the link text
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^\)]*\)'),
      (Match match) => match.group(1) ?? ''
    );
    
    // Remove markdown formatting
    text = text.replaceAll(RegExp(r'[*_#>-]'), '');
    
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }

  Future<void> stop() async {
    if (!isInitialized.value) return;
    
    try {
      print('Stopping TTS...');
      await _flutterTts.stop();
      isSpeaking.value = false;
      print('TTS stopped successfully');
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  @override
  void onClose() {
    print('VoiceService onClose called');
    _flutterTts.stop();
    super.onClose();
  }
} 