import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ollama_service.dart';

class QuestionAnsweringScreen extends StatefulWidget {
  const QuestionAnsweringScreen({super.key});

  @override
  State<QuestionAnsweringScreen> createState() => _QuestionAnsweringScreenState();
}

class _QuestionAnsweringScreenState extends State<QuestionAnsweringScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _isAnswering = false;
  bool _hasContext = false;

  Future<void> _answerQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAnswering) return;

    setState(() {
      _isAnswering = true;
      _answerController.clear();
    });

    try {
      final context = _hasContext ? _contextController.text.trim() : null;
      final answer = await OllamaService.answerQuestion(
        question,
        context: context,
      );
      
      setState(() {
        _answerController.text = answer.trim();
        _isAnswering = false;
      });
    } catch (e) {
      setState(() {
        _answerController.text = 'Error: ${e.toString()}';
        _isAnswering = false;
      });
    }
  }

  void _copyAnswer() {
    if (_answerController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _answerController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer copied to clipboard')),
      );
    }
  }

  void _clearAll() {
    _questionController.clear();
    _contextController.clear();
    _answerController.clear();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _contextController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Answering'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask a question',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Your Question',
                hintText: 'What would you like to know?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _hasContext,
                  onChanged: (value) {
                    setState(() {
                      _hasContext = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'Provide context (optional)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_hasContext) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _contextController,
                decoration: const InputDecoration(
                  labelText: 'Context',
                  hintText: 'Provide any relevant context for the question...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isAnswering ? null : _answerQuestion,
              icon: _isAnswering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.question_answer),
              label: Text(_isAnswering ? 'Thinking...' : 'Get Answer'),
            ),
            if (_answerController.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Answer:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyAnswer,
                        tooltip: 'Copy answer',
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _answerController.text,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Tip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can provide context to get more accurate answers. '
                      'For example, provide a paragraph of text and ask questions about it.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

