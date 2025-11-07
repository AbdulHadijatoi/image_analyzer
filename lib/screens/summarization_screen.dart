import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ollama_service.dart';

class SummarizationScreen extends StatefulWidget {
  const SummarizationScreen({super.key});

  @override
  State<SummarizationScreen> createState() => _SummarizationScreenState();
}

class _SummarizationScreenState extends State<SummarizationScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  int _maxLength = 100;
  bool _isSummarizing = false;

  Future<void> _summarize() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSummarizing) return;

    setState(() {
      _isSummarizing = true;
      _summaryController.clear();
    });

    try {
      final summary = await OllamaService.summarize(text, maxLength: _maxLength);
      
      setState(() {
        _summaryController.text = summary.trim();
        _isSummarizing = false;
      });
    } catch (e) {
      setState(() {
        _summaryController.text = 'Error: ${e.toString()}';
        _isSummarizing = false;
      });
    }
  }

  void _copySummary() {
    if (_summaryController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _summaryController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary copied to clipboard')),
      );
    }
  }

  void _clearAll() {
    _textController.clear();
    _summaryController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Summarization'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter text to summarize',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to Summarize',
                hintText: 'Paste or type the text you want to summarize...',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Max length: '),
                Expanded(
                  child: Slider(
                    value: _maxLength.toDouble(),
                    min: 50,
                    max: 500,
                    divisions: 9,
                    label: '$_maxLength words',
                    onChanged: (value) {
                      setState(() {
                        _maxLength = value.toInt();
                      });
                    },
                  ),
                ),
                Text('$_maxLength words'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSummarizing ? null : _summarize,
              icon: _isSummarizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.summarize),
              label: Text(_isSummarizing ? 'Summarizing...' : 'Summarize'),
            ),
            if (_summaryController.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Summary:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copySummary,
                        tooltip: 'Copy summary',
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _summaryController.text,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Summary length: ${_summaryController.text.split(' ').length} words',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

