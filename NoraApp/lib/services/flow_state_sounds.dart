import 'dart:math';
import 'dart:typed_data';

/// FlowStateSoundGenerator — Procedural ambient sound generator for focus.
///
/// Generates white noise, brown noise, rain, and other ambient sounds
/// using pure math — no external files or APIs needed.
///
/// Uses the device's audio output via audioplayers for real-time playback.
class FlowStateSoundGenerator {
  static const _sampleRate = 44100;

  /// Generate white noise buffer (random static).
  static Uint8List generateWhiteNoise({int seconds = 10}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2); // 16-bit PCM

    for (int i = 0; i < samples; i++) {
      final value = random.nextInt(65536) - 32768;
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Generate brown noise buffer (deeper, rumbling static).
  static Uint8List generateBrownNoise({int seconds = 10}) {
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

  /// Generate pink noise buffer (1/f noise, natural sounding).
  static Uint8List generatePinkNoise({int seconds = 10}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    // Voss-McCartney algorithm
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

  /// Generate rain-like sound (filtered noise with random droplets).
  static Uint8List generateRain({int seconds = 10, double intensity = 0.5}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double lastOut = 0;
    for (int i = 0; i < samples; i++) {
      // Base: brown noise filtered
      final white = random.nextDouble() * 2 - 1;
      lastOut = (lastOut + (0.02 * white)) / 1.02;

      // Random rain drops (clicks)
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

  /// Generate ocean waves (slow modulation of brown noise).
  static Uint8List generateOceanWaves({int seconds = 30}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double brown = 0;
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Wave modulation: slow sine at 0.1 Hz
      final wave = (sin(2 * pi * 0.1 * t) + 1) / 2;

      // Brown noise base
      final white = random.nextDouble() * 2 - 1;
      brown = (brown + (0.02 * white)) / 1.02;

      // Mix wave with brown noise
      final combined = brown * wave * 0.8;
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Generate forest ambience (pink noise + bird chirps).
  static Uint8List generateForest({int seconds = 30}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    // Pink noise base (Voss-McCartney)
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

      // Bird chirps: random sine bursts at high frequencies
      if (random.nextDouble() < 0.00005) {
        // Simulate chirp with harmonics
        final freq = 2000 + random.nextDouble() * 3000;
        for (int k = 0; k < 50; k++) {
          final idx = i + k;
          if (idx >= samples) break;
          final chirpT = k / _sampleRate;
          final chirp = sin(2 * pi * freq * chirpT) * exp(-chirpT * 20) * 0.15;
          final existing = buffer.getInt16(idx * 2, Endian.little);
          final mixed = (existing + (chirp * 32767)).clamp(-32768, 32767).toInt();
          buffer.setInt16(idx * 2, mixed, Endian.little);
        }
      }

      final combined = (sum / octaves * 0.7);
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Generate café ambience (murmur + clinks).
  static Uint8List generateCafe({int seconds = 30}) {
    final random = Random();
    final samples = _sampleRate * seconds;
    final buffer = ByteData(samples * 2);

    double brown = 0;
    for (int i = 0; i < samples; i++) {
      // Murmur: filtered brown noise
      final white = random.nextDouble() * 2 - 1;
      brown = (brown + (0.01 * white)) / 1.01;

      // Occasional clink (high-freq burst)
      if (random.nextDouble() < 0.00003) {
        final freq = 3000 + random.nextDouble() * 2000;
        for (int k = 0; k < 30; k++) {
          final idx = i + k;
          if (idx >= samples) break;
          final clinkT = k / _sampleRate;
          final clink = sin(2 * pi * freq * clinkT) * exp(-clinkT * 30) * 0.1;
          final existing = buffer.getInt16(idx * 2, Endian.little);
          final mixed = (existing + (clink * 32767)).clamp(-32768, 32767).toInt();
          buffer.setInt16(idx * 2, mixed, Endian.little);
        }
      }

      final combined = (brown * 0.6);
      final value = (combined * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(i * 2, value, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Get all available sound types.
  static List<SoundType> get availableSounds => SoundType.values;
}

/// Available ambient sound types.
enum SoundType {
  whiteNoise("White Noise", "Static hiss — blocks distractions", "🌊"),
  brownNoise("Brown Noise", "Deep rumble — best for deep focus", "🏔️"),
  pinkNoise("Pink Noise", "Natural 1/f — balanced and calming", "🌿"),
  rain("Rain", "Gentle rainfall — soothing and consistent", "🌧️"),
  oceanWaves("Ocean Waves", "Slow waves — calming rhythm", "🌊"),
  forest("Forest", "Birds and wind — natural ambience", "🌲"),
  cafe("Café", "Background murmur — mild stimulation", "☕");

  final String name;
  final String description;
  final String emoji;

  const SoundType(this.name, this.description, this.emoji);
}
