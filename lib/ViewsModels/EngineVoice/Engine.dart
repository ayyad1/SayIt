import 'package:supertonic_flutter/supertonic_flutter.dart';

typedef DownloadProgress = void Function(
  int completed,
  int total,
  String file,
  double progress,
);

class SpeechService {
  final SupertonicTTS _tts = SupertonicTTS();
  final TTSAudioPlayer _player = TTSAudioPlayer();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;


  Future<void> initialize({
    DownloadProgress? onProgress,
  }) async {
    if (_isInitialized) return;

    final ready = await SupertonicTTS.modelsReady();

    if (!ready) {
      await SupertonicTTS.preDownloadModels(
        onProgress: (completed, total, file, progress) {
          onProgress?.call(completed, total, file, progress);
        },
      );
    }

    await _tts.initialize();

    _isInitialized = true;
  }


  Future<void> speak({
    required String text,
    String language = 'en',
    String voiceStyle = 'M1',
    double speechSpeed = 1.0,
  }) async {
    if (!_isInitialized) {
      throw StateError('Speech engine is not initialized.');
    }

    if (text.trim().isEmpty) {
      throw ArgumentError('Text cannot be empty.');
    }

    final result = await _tts.synthesize(
      text,
      language: language,
      voiceStyle: voiceStyle,
      config: TTSConfig(
        speechSpeed: speechSpeed,
        denoisingSteps: 5,
      ),
    );

    await _player.play(result);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
    _tts.dispose();
  }
}