import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ollama_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Hindi',
    'Dutch',
    'Turkish',
    'Polish',
  ];
  String _selectedLanguage = 'Spanish';
  bool _isTranslating = false;

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTranslating) return;

    setState(() {
      _isTranslating = true;
      _translationController.clear();
    });

    try {
      final translation = await OllamaService.translate(text, _selectedLanguage);
      
      setState(() {
        _translationController.text = translation.trim();
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _translationController.text = 'Error: ${e.toString()}';
        _isTranslating = false;
      });
    }
  }

  void _swapLanguages() {
    final tempText = _textController.text;
    _textController.text = _translationController.text;
    _translationController.text = tempText;
  }

  void _copyTranslation() {
    if (_translationController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _translationController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard')),
      );
    }
  }

  void _clearAll() {
    _textController.clear();
    _translationController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter text to translate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Source Text',
                hintText: 'Enter the text you want to translate',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Target Language',
                border: OutlineInputBorder(),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value ?? 'Spanish';
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isTranslating ? null : _translate,
              icon: _isTranslating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate),
              label: Text(_isTranslating ? 'Translating...' : 'Translate'),
            ),
            if (_translationController.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Translation to $_selectedLanguage:',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: _swapLanguages,
                        tooltip: 'Swap text',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyTranslation,
                        tooltip: 'Copy translation',
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearAll,
                        tooltip: 'Clear all',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _translationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                readOnly: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

