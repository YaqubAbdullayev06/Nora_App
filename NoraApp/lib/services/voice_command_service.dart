import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// VoiceCommandService — Handles speech-to-text recognition
/// and routes recognized text through the AI command pipeline.
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _isListening = false;

  /// Callback for when speech is recognized.
  void Function(String text)? onRecognized;

  /// Callback for listening state changes.
  void Function(bool isListening)? onListeningChanged;

  /// Callback for errors.
  void Function(String error)? onError;

  bool get isListening => _isListening;
  bool get isAvailable => _speech.isAvailable;

  /// Initialize the speech recognition engine.
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;

    try {
      _initialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: false,
      );

      if (_initialized) {
        debugPrint('VoiceCommandService: initialized successfully');
      } else {
        debugPrint('VoiceCommandService: initialization failed — speech service may not be installed');
      }

      return _initialized;
    } catch (e) {
      debugPrint('VoiceCommandService: init error: $e');
      return false;
    }
  }

  /// Start listening for voice input.
  Future<void> startListening() async {
    if (_isListening) return;

    final available = await initialize();
    if (!available) {
      onError?.call(
        'Speech recognition is not available. '
        'Make sure your device has Google Speech Services installed '
        'and microphone permission is granted.',
      );
      return;
    }

    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
          cancelOnError: true,
          partialResults: true,
        ),
      );

      _isListening = true;
      onListeningChanged?.call(true);
      debugPrint('VoiceCommandService: started listening');
    } catch (e) {
      debugPrint('VoiceCommandService: start error: $e');
      onError?.call('Failed to start listening: $e');
    }
  }

  /// Stop listening for voice input.
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      onListeningChanged?.call(false);
      debugPrint('VoiceCommandService: stopped listening');
    } catch (e) {
      debugPrint('VoiceCommandService: stop error: $e');
    }
  }

  /// Cancel the current listening session.
  Future<void> cancel() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      onListeningChanged?.call(false);
    } catch (e) {
      debugPrint('VoiceCommandService: cancel error: $e');
    }
  }

  /// Handle speech recognition results.
  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();

    if (text.isNotEmpty && result.finalResult) {
      debugPrint('VoiceCommandService: recognized "$text"');
      onRecognized?.call(text);
    }
  }

  /// Handle speech recognition status changes.
  void _onStatus(String status) {
    debugPrint('VoiceCommandService: status=$status');

    switch (status) {
      case 'notListening':
      case 'done':
      case 'cancelled':
        _isListening = false;
        onListeningChanged?.call(false);
        break;
      case 'listening':
        _isListening = true;
        onListeningChanged?.call(true);
        break;
    }
  }

  /// Handle speech recognition errors.
  void _onError(SpeechRecognitionError error) {
    debugPrint('VoiceCommandService: error=${error.errorMsg}');
    _isListening = false;
    onListeningChanged?.call(false);

    // Map error strings to user-friendly messages
    String message;
    if (error.errorMsg.contains('no_match')) {
      message = 'Could not understand. Please try again.';
    } else if (error.errorMsg.contains('timeout')) {
      message = 'Listening timed out. Please try again.';
    } else if (error.errorMsg.contains('network')) {
      message = 'Network error. Check your connection.';
    } else if (error.errorMsg.contains('permission')) {
      message = 'Microphone permission denied. Please enable it in Settings.';
    } else {
      message = 'Voice recognition error. Please try again.';
    }

    onError?.call(message);
  }

  /// Get available locales (for future localization).
  Future<List<LocaleName>> getAvailableLocales() async {
    final available = await initialize();
    if (!available) return [];

    try {
      return await _speech.locales();
    } catch (e) {
      debugPrint('VoiceCommandService: locale error: $e');
      return [];
    }
  }

  /// Dispose resources.
  void dispose() {
    _speech.cancel();
    _isListening = false;
  }
}
