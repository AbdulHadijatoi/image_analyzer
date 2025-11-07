import 'package:flutter/material.dart';
import 'image_analyzer_screen.dart';
import 'image_editor_screen.dart';
import 'chat_screen.dart';
import 'code_generation_screen.dart';
import 'translation_screen.dart';
import 'summarization_screen.dart';
import 'question_answering_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama AI Features'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Explore AI-Powered Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any feature to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _FeatureCard(
            icon: Icons.image,
            title: 'Image Analyzer',
            description: 'Analyze images and generate titles and descriptions using vision AI',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImageAnalyzerScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.edit,
            title: 'Image Editor',
            description: 'Edit images: resize, crop, rotate, adjust brightness/contrast, and apply filters',
            color: Colors.pink,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImageEditorScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.chat_bubble,
            title: 'AI Chat',
            description: 'Have conversations with AI. Ask questions and get intelligent responses',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.code,
            title: 'Code Generation',
            description: 'Generate code snippets, functions, and scripts in any programming language',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CodeGenerationScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.translate,
            title: 'Translation',
            description: 'Translate text between multiple languages with AI',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TranslationScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.summarize,
            title: 'Text Summarization',
            description: 'Summarize long texts, articles, and documents into concise summaries',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SummarizationScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.help_outline,
            title: 'Question Answering',
            description: 'Ask questions and get detailed, accurate answers from AI',
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuestionAnsweringScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

