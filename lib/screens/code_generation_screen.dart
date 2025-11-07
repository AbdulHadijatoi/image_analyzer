import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ollama_service.dart';

class CodeGenerationScreen extends StatefulWidget {
  const CodeGenerationScreen({super.key});

  @override
  State<CodeGenerationScreen> createState() => _CodeGenerationScreenState();
}

class _CodeGenerationScreenState extends State<CodeGenerationScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final List<String> _languages = [
    'any',
    'Python',
    'JavaScript',
    'TypeScript',
    'Java',
    'C++',
    'C',
    'C#',
    'Go',
    'Rust',
    'Swift',
    'Kotlin',
    'Dart',
    'PHP',
    'Ruby',
    'HTML',
    'CSS',
    'SQL',
  ];
  String _selectedLanguage = 'any';
  bool _isGenerating = false;

  Future<void> _generateCode() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _codeController.clear();
    });

    try {
      final code = await OllamaService.generateCode(
        description,
        language: _selectedLanguage,
      );
      
      setState(() {
        _codeController.text = code;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _codeController.text = 'Error: ${e.toString()}';
        _isGenerating = false;
      });
    }
  }

  void _copyCode() {
    if (_codeController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _codeController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied to clipboard')),
      );
    }
  }

  void _clearAll() {
    _descriptionController.clear();
    _codeController.clear();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Generation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Describe what code you want to generate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Programming Language',
                border: OutlineInputBorder(),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang.toLowerCase(),
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value ?? 'any';
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Code Description',
                hintText: 'e.g., Create a function to sort an array of numbers',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateCode,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.code),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Code'),
            ),
            if (_codeController.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Generated Code:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyCode,
                        tooltip: 'Copy code',
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
              Container(
                constraints: const BoxConstraints(minHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: TextField(
                  controller: _codeController,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: null,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

