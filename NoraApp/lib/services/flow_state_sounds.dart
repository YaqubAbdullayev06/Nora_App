import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// FlowStateSoundService — Procedural ambient sound generator with playback.
///
/// Generates white noise, brown noise, rain, and other ambient sounds
/// using pure math, then plays them via audioplayers.
class FlowStateSoundService {
  static final FlowStateSoundService _instance = FlowStateSoundService._();
  factory FlowStateSoundService() => _instance;
  FlowStateSoundService._();

  static const _sampleRate = 44100;
  static const _channels = 1;
  static const _bitsPerSample = 16;

  final AudioPlayer _player = AudioPlayer();
  SoundType? _currentSound;
  bool _isPlaying = false;
  String? _tempFilePath;

  /// Whether audio is currently playing.
  bool get isPlaying => _isPlaying;

  /// The currently playing sound type.
  SoundType? get currentSound => _currentSound;

  /// Stream of player state changes.
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  /// Play a sound type. If the same sound is already playing, stop it.
  Future<void> play(SoundType sound) async {
    if (_isPlaying && _currentSound == sound) {
      await stop();
      return;
    }

    await stop();

    _currentSound = sound;
    _isPlaying = true;

    // Generate audio buffer
    final Uint8List pcmData = _generateSound(sound, seconds: 30);

    // Convert to WAV
    final wavData = _pcmToWav(pcmData, _sampleRate, _channels, _bitsPerSample);

    // Write to temp file
    final tempDir = await getTemporaryDirectory();
    _tempFilePath = '${tempDir.id}_${sound.name}.wav';
    final file = File('${tempDir.path}/$_tempFilePath');
    await file.writeAsBytes(wavData);

    // Play from file with looping
    await _player.play(DeviceFileSource(file.path), volume: 0.8);
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  /// Stop playback.
  Future<void> stop() async {
    _isPlaying = false;
    _currentSound = null;
    await _player.stop();

    // Clean up temp file
    if (_tempFilePath != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$_tempFilePath');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _tempFilePath = null;
    }
  }

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Dispose resources.
  void dispose() {
    _player.dispose();
  }

  // ─── Sound Generation ────────────────────────────────────────────

  Uint8List _generateSound(SoundType sound, {int seconds = 30}) {
    switch (sound) {
      case SoundType.whiteNoise:
        return _generateWhiteNoise(seconds: seconds);
      case SoundType.brownNoise:
        return _generateBrownNoise(seconds: seconds);
      case SoundType.pinkNoise:
        return _generatePinkNoise(seconds: seconds);
      case SoundType.rain:
        return _generateRain(seconds: seconds);
      case SoundType.oceanWaves:
        return _generateOceanWaves(seconds: seconds);
      case SoundType.forest:
        return _generateForest(seconds: seconds);
      case SoundType.cafe:
        return _generateCafe(seconds: seconds);
    }
  }

  Uint8List _generateWhiteNoise({int seconds = 10}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    for (int i = 0; i < samples; i++) {
      final value = random.nextInt(65536) - 32768;
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generateBrownNoise({int seconds = 10}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double lastOut = 0;
    for (int i = 0; i < samples; i++) {
      final white = random.nextDouble() * 2 - 1;
      lastOut = (lastOut + (0.02 * white)) / 1.02;
      final value = (lastOut * 3.5 * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generatePinkNoise({int seconds = 10}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double sum = 0;
    final octaves = 16;
    final running = List.filled(octaves, 0.0);

    for (int i = 0; i < samples; i++) {
      for (int j = 0; j < octaves; j++) {
        if (i % (1 << j) == 0) {
          running[j] = random.nextDouble() * 2 - 1;
        }
      }
      sum = running.reduce((a, b) => a + b);
      final value = (sum / octaves * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generateRain({int seconds = 10, double intensity = 0.5}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double lastOut = 0;
    for (int i = 0; i < samples; i++) {
      final white = random.nextDouble() * 2 - 1;
      lastOut = (lastOut + (0.02 * white)) / 1.02;

      double drop = 0;
      if (random.nextDouble() < intensity * 0.001) {
        drop = (random.nextDouble() * 2 - 1) * 0.3;
      }

      final combined = (lastOut + drop) * 0.5;
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generateOceanWaves({int seconds = 30}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double brown = 0;
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final wave = (sin(2 * pi * 0.1 * t) + 1) / 2;

      final white = random.nextDouble() * 2 - 1;
      brown = (brown + (0.02 * white)) / 1.02;

      final combined = brown * wave * 0.8;
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generateForest({int seconds = 30}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double sum = 0;
    final octaves = 16;
    final running = List.filled(octaves, 0.0);

    for (int i = 0; i < samples; i++) {
      for (int j = 0; j < octaves; j++) {
        if (i % (1 << j) == 0) {
          running[j] = random.nextDouble() * 2 - 1;
        }
      }
      sum = running.reduce((a, b) => a + b);

      if (random.nextDouble() < 0.00005) {
        final freq = 2000 + random.nextDouble() * 3000;
        for (int k = 0; k < 50; k++) {
          final idx = i + k;
          if (idx >= samples) break;
          final chirpT = k / _sampleRate;
          final chirp =
              sin(2 * pi * freq * chirpT) * exp(-chirpT * 20) * 0.15;
          final existing = buffer.getInt16(idx * 2, Endian.little);
          final mixed =
              (existing + (chirp * 32767)).clamp(-32768, 32767).toInt();
          buffer.setInt16(idx * 2, mixed, Endian.little);
        }
      }

      final combined = (sum / octaves * 0.7);
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generateCafe({int seconds = 30}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double brown = 0;
    for (int i = 0; i < samples; i++) {
      final white = random.nextDouble() * 2 - 1;
      brown = (brown + (0.01 * white)) / 1.01;

      if (random.nextDouble() < 0.00003) {
        final freq = 3000 + random.nextDouble() * 2000;
        for (int k = 0; k < 30; k++) {
          final idx = i + k;
          if (idx >= samples) break;
          final clinkT = k / _sampleRate;
          final clink =
              sin(2 * pi * freq * clinkT) * exp(-clinkT * 30) * 0.1;
          final existing = buffer.getInt16(idx * 2, Endian.little);
          final mixed =
              (existing + (clink * 32767)).clamp(-32768, 32767).toInt();
          buffer.setInt16(idx * 2, mixed, Endian.little);
        }
      }

      final combined = (brown * 0.6);
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  // ─── WAV Conversion ──────────────────────────────────────────────

  /// Convert raw PCM bytes to a WAV file bytes.
  Uint8List _pcmToWav(
      Uint8List pcmData, int sampleRate, int channels, int bitsPerSample) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset, 0x52); offset++; // R
    buffer.setUint8(offset, 0x49); offset++; // I
    buffer.setUint8(offset, 0x46); offset++; // F
    buffer.setUint8(offset, 0x46); offset++; // F
    buffer.setUint32(offset, fileSize, Endian.little); offset += 4;
    buffer.setUint8(offset, 0x57); offset++; // W
    buffer.setUint8(offset, 0x41); offset++; // A
    buffer.setUint8(offset, 0x56); offset++; // V
    buffer.setUint8(offset, 0x45); offset++; // E

    // fmt chunk
    buffer.setUint8(offset, 0x66); offset++; // f
    buffer.setUint8(offset, 0x6D); offset++; // m
    buffer.setUint8(offset, 0x74); offset++; // t
    buffer.setUint8(offset, 0x20); offset++; // (space)
    buffer.setUint32(offset, 16, Endian.little); offset += 4; // chunk size
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // PCM format
    buffer.setUint16(offset, channels, Endian.little); offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little); offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little); offset += 4;
    buffer.setUint16(offset, blockAlign, Endian.little); offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little); offset += 2;

    // data chunk
    buffer.setUint8(offset, 0x64); offset++; // d
    buffer.setUint8(offset, 0x61); offset++; // a
    buffer.setUint8(offset, 0x74); offset++; // t
    buffer.setUint8(offset, 0x61); offset++; // a
    buffer.setUint32(offset, dataSize, Endian.little); offset += 4;

    // Combine header + PCM data
    final wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, buffer.buffer.asUint8List());
    wavBytes.setRange(44, 44 + dataSize, pcmData);

    return wavBytes;
  }
}

/// Available ambient sound types.
enum SoundType {
  whiteNoise("White Noise", "Static hiss — blocks distractions",
      Icons.waves_rounded),
  brownNoise("Brown Noise", "Deep rumble — best for deep focus",
      Icons.terrain_rounded),
  pinkNoise(
      "Pink Noise", "Natural 1/f — balanced and calming", Icons.eco_rounded),
  rain("Rain", "Gentle rainfall — soothing and consistent",
      Icons.grain_rounded),
  oceanWaves("Ocean Waves", "Slow waves — calming rhythm",
      Icons.waves_rounded),
  forest("Forest", "Birds and wind — natural ambience",
      Icons.forest_rounded),
  cafe("Café", "Background murmur — mild stimulation", Icons.coffee_rounded);

  final String name;
  final String description;
  final IconData icon;

  const SoundType(this.name, this.description, this.icon);
}
