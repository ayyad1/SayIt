
import 'package:arm_learn_english/ViewsModels/EngineVoice/Engine.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(MaterialApp(home: SupertonicTestScreen(),));
}


class SupertonicTestScreen extends StatefulWidget {
  const SupertonicTestScreen({super.key});

  @override
  State<SupertonicTestScreen> createState() =>
      _SupertonicTestScreenState();
}

class _SupertonicTestScreenState
    extends State<SupertonicTestScreen> {
  final SpeechService _speech = SpeechService();

  final TextEditingController _controller =
      TextEditingController(
    text: 'مرحباً! هذه تجربة لمحرك تحويل النص إلى صوت.',
  );

  bool _isInitializing = false;
  bool _isReady = false;
  bool _isGenerating = false;

  String _language = 'ar';
  String _voice = 'M1';
  String _status = 'المحرك غير جاهز';
  String? _error;

  double _progress = 0;
  double _speed = 1.0;

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _error = null;
      _status = 'جاري تجهيز النموذج...';
      _progress = 0;
    });

    try {
      await _speech.initialize(
        onProgress: (completed, total, file, progress) {
          if (!mounted) return;

          setState(() {
            _progress = total > 0
                ? ((completed + progress) / total)
                    .clamp(0.0, 1.0)
                    .toDouble()
                : 0;

            _status =
                'تنزيل الملفات: $completed/$total\n'
                '$file - ${(progress * 100).toInt()}%';
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isReady = true;
        _status = 'المحرك جاهز للاستخدام';
        _progress = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _status = 'فشل تجهيز المحرك';
      });
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _speak() async {
    if (!_isReady || _controller.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _status = 'جاري توليد الصوت...';
    });

    try {
      await _speech.speak(
        text: _controller.text,
        language: _language,
        voiceStyle: _voice,
        speechSpeed: _speed,
      );

      if (!mounted) return;

      setState(() {
        _status = 'اكتملت القراءة';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _status = 'حدث خطأ أثناء توليد الصوت';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supertonic TTS Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            if (_isInitializing)
              LinearProgressIndicator(
                value: _progress,
              ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isInitializing || _isReady
                  ? null
                  : _initialize,
              icon: const Icon(Icons.download),
              label: const Text('Download & Initialize Model'),
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'ar',
                  child: Text('العربية'),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
              onChanged: _isGenerating
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _language = value;
                        _controller.text = value == 'ar'
                            ? 'مرحباً! هذه تجربة لمحرك تحويل النص إلى صوت.'
                            : 'Hello! This is a local text to speech test.';
                      });
                    },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _voice,
              decoration: const InputDecoration(
                labelText: 'Voice Style',
                border: OutlineInputBorder(),
              ),
              items: [
                ...['M1', 'M2', 'M3', 'M4', 'M5',
                    'F1', 'F2', 'F3', 'F4', 'F5']
                    .map(
                  (voice) => DropdownMenuItem(
                    value: voice,
                    child: Text(voice),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _voice = value);
                }
              },
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _controller,
              maxLines: 6,
              textDirection: _language == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Text to Read',
                hintText: 'Enter your text...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Speech Speed: ${_speed.toStringAsFixed(2)}x',
            ),

            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() => _speed = value);
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: !_isReady ||
                      _isGenerating ||
                      _isInitializing
                  ? null
                  : _speak,
              icon: const Icon(Icons.volume_up),
              label: Text(
                _isGenerating
                    ? 'Generating / Playing...'
                    : 'Generate & Play Speech',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
