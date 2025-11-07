import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageDescription {
  final String title;
  final String description;

  ImageDescription({
    required this.title,
    required this.description,
  });
}

class OllamaService {
  // Using your computer's IP address for physical device connection
  // For physical devices, use your computer's IP address instead of localhost
  static const String OLLAMA_BASE_URL = 'http://192.168.100.6:11434';
  
  static const String VISION_MODEL = 'llava:7b'; // Using llava:7b model for image analysis
  static const String TEXT_MODEL = 'llama3.2:latest'; // Using llama3.2 for text generation (can use llama2, mistral, etc.)
  
  /// Get available text models (fallback list)
  static const List<String> TEXT_MODEL_FALLBACKS = [
    'llama3.2:latest',
    'llama3.2',
    'llama3.1',
    'llama3',
    'llama2',
    'mistral',
    'phi',
  ];

  /// Generates a title and description for an image using Ollama's vision model
  static Future<ImageDescription> describeImage(File imageFile) async {
    try {
      // Read image as base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Prepare the prompt to get both title and description
      const prompt = '''
Analyze this image and provide:
1. A concise title (3-7 words)
2. A detailed description (2-3 sentences)

Format your response as:
Title: [your title here]
Description: [your description here]
''';

      // Prepare the request body for Ollama API
      final requestBody = {
        'model': VISION_MODEL,
        'prompt': prompt,
        'images': [base64Image],
        'stream': false,
      };

      // Make the API call to Ollama
      final response = await http.post(
        Uri.parse('$OLLAMA_BASE_URL/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request to Ollama timed out');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final responseText = jsonResponse['response'] as String? ?? '';

        // Parse the response to extract title and description
        return _parseResponse(responseText);
      } else {
        throw Exception(
            'Ollama API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // If the model is not available, provide a fallback
      if (e.toString().contains('model') ||
          e.toString().contains('not found')) {
        throw Exception(
            'Ollama model "$VISION_MODEL" not found. Please run: ollama pull $VISION_MODEL');
      }
      throw Exception('Error analyzing image with Ollama: $e');
    }
  }

  /// Parses the Ollama response to extract title and description
  static ImageDescription _parseResponse(String responseText) {
    String title = 'Untitled Image';
    String description = 'No description available';

    // Try to extract title and description from the formatted response
    final titleMatch = RegExp(r'Title:\s*(.+?)(?:\n|Description:)',
            caseSensitive: false, dotAll: true)
        .firstMatch(responseText);
    final descMatch = RegExp(r'Description:\s*(.+?)(?:\n\n|\Z)',
            caseSensitive: false, dotAll: true)
        .firstMatch(responseText);

    if (titleMatch != null) {
      title = titleMatch.group(1)?.trim() ?? title;
    }
    if (descMatch != null) {
      description = descMatch.group(1)?.trim() ?? description;
    } else {
      // Fallback: use the entire response as description if parsing fails
      description = responseText.trim();
      // Try to extract first line as title
      final lines = responseText.split('\n');
      if (lines.isNotEmpty) {
        title = lines.first.trim();
        if (title.length > 50) {
          title = '${title.substring(0, 47)}...';
        }
      }
    }

    // Clean up the title and description (remove leading/trailing quotes)
    // Use regular string with escaped $ for end-of-string anchor
    title = title.replaceAll(RegExp('^["\']|["\']\$'), '');
    description = description.replaceAll(RegExp('^["\']|["\']\$'), '');

    return ImageDescription(title: title, description: description);
  }

  /// Generate text response from a prompt
  static Future<String> generateText(String prompt, {String? model}) async {
    String modelToUse = model ?? await findAvailableTextModel();
    
    try {
      final requestBody = {
        'model': modelToUse,
        'prompt': prompt,
        'stream': false,
      };

      final response = await http.post(
        Uri.parse('$OLLAMA_BASE_URL/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Request to Ollama timed out');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final content = jsonResponse['response'];
        if (content is String) {
          return content;
        }
        return content?.toString() ?? 'No response from AI';
      } else {
        final errorBody = response.body;
        if (response.statusCode == 404 || errorBody.contains('not found') || errorBody.contains('model')) {
          // Get available models for better error message
          final availableModels = await getAvailableModels();
          final availableText = availableModels.where((m) => 
            !m.contains('llava') && !m.contains('vision')
          ).toList();
          
          String errorMsg = 'Text model not found.\n\n';
          if (availableText.isNotEmpty) {
            errorMsg += 'Available text models: ${availableText.join(", ")}\n\n';
          }
          errorMsg += 'Please install a text model:\n  ollama pull llama3.2\n\n';
          errorMsg += 'Or try:\n  ollama pull llama2\n  ollama pull mistral';
          
          throw Exception(errorMsg);
        }
        throw Exception('Ollama API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      final errorStr = e.toString();
      // Don't re-throw if it's already a formatted error message
      if (errorStr.contains('Please install') || errorStr.contains('Available text models')) {
        rethrow;
      }
      if (errorStr.contains('model') || errorStr.contains('not found') || errorStr.contains('404')) {
        throw Exception('Ollama text model not found.\n\nPlease install a text model:\n  ollama pull llama3.2\n\nOr try:\n  ollama pull llama2\n  ollama pull mistral');
      }
      throw Exception('Error generating text: $e');
    }
  }

  /// Chat with AI (conversational context)
  static Future<String> chat(List<Map<String, String>> messages, {String? model}) async {
    String modelToUse = model ?? await findAvailableTextModel();
    
    try {
      // Ensure messages are properly formatted
      final formattedMessages = messages.map((msg) {
        return {
          'role': msg['role']?.toString() ?? 'user',
          'content': msg['content']?.toString() ?? '',
        };
      }).toList();

      final requestBody = {
        'model': modelToUse,
        'messages': formattedMessages,
        'stream': false,
      };

      final response = await http.post(
        Uri.parse('$OLLAMA_BASE_URL/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Request to Ollama timed out');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final content = jsonResponse['message']?['content'] ?? jsonResponse['response'];
        if (content is String) {
          return content;
        }
        return content?.toString() ?? 'No response from AI';
      } else {
        final errorBody = response.body;
        if (response.statusCode == 404 || errorBody.contains('not found') || errorBody.contains('model')) {
          // Get available models for better error message
          final availableModels = await getAvailableModels();
          final availableText = availableModels.where((m) => 
            !m.contains('llava') && !m.contains('vision')
          ).toList();
          
          String errorMsg = 'Text model not found.\n\n';
          if (availableText.isNotEmpty) {
            errorMsg += 'Available text models: ${availableText.join(", ")}\n\n';
          }
          errorMsg += 'Please install a text model:\n  ollama pull llama3.2\n\n';
          errorMsg += 'Or try:\n  ollama pull llama2\n  ollama pull mistral';
          
          throw Exception(errorMsg);
        }
        throw Exception('Ollama API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      final errorStr = e.toString();
      // Don't re-throw if it's already a formatted error message
      if (errorStr.contains('Please install') || errorStr.contains('Available text models')) {
        rethrow;
      }
      if (errorStr.contains('model') || errorStr.contains('not found') || errorStr.contains('404')) {
        throw Exception('Ollama text model not found.\n\nPlease install a text model:\n  ollama pull llama3.2\n\nOr try:\n  ollama pull llama2\n  ollama pull mistral');
      }
      throw Exception('Error in chat: $e');
    }
  }

  /// Generate code based on a description
  static Future<String> generateCode(String description, {String language = 'any'}) async {
    final prompt = language == 'any'
        ? 'Write code for the following task. Provide clean, well-commented code:\n\n$description'
        : 'Write $language code for the following task. Provide clean, well-commented code:\n\n$description';
    
    return generateText(prompt);
  }

  /// Translate text to target language
  static Future<String> translate(String text, String targetLanguage) async {
    final prompt = 'Translate the following text to $targetLanguage. Only provide the translation without any additional text:\n\n$text';
    return generateText(prompt);
  }

  /// Summarize text
  static Future<String> summarize(String text, {int maxLength = 100}) async {
    final prompt = 'Summarize the following text in approximately $maxLength words. Provide a concise summary:\n\n$text';
    return generateText(prompt);
  }

  /// Answer a question based on context
  static Future<String> answerQuestion(String question, {String? context}) async {
    final prompt = context != null
        ? 'Based on the following context, answer the question:\n\nContext: $context\n\nQuestion: $question\n\nAnswer:'
        : 'Answer the following question clearly and concisely:\n\n$question\n\nAnswer:';
    
    return generateText(prompt);
  }

  /// Get list of available models from Ollama (returns full model names)
  static Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$OLLAMA_BASE_URL/api/tags'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final models = jsonResponse['models'] as List?;
        if (models != null) {
          return models
              .map((model) => model['name'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Find an available text model (fallback mechanism)
  static Future<String> findAvailableTextModel() async {
    try {
      final availableModels = await getAvailableModels();
      
      if (availableModels.isEmpty) {
        return TEXT_MODEL; // Let error handling take over
      }
      
      // Try to find TEXT_MODEL first (exact match or starts with)
      for (final model in availableModels) {
        if (model == TEXT_MODEL || model.startsWith('${TEXT_MODEL.split(':')[0]}:')) {
          return model;
        }
      }
      
      // Try fallback models in order
      for (final fallback in TEXT_MODEL_FALLBACKS) {
        final fallbackBase = fallback.split(':')[0];
        for (final model in availableModels) {
          if (model == fallback || model.startsWith('$fallbackBase:')) {
            return model;
          }
        }
      }
      
      // If no text model found, return first available model (might be vision model, but better than nothing)
      // Or return default and let error handling provide helpful message
      return TEXT_MODEL;
    } catch (e) {
      return TEXT_MODEL;
    }
  }

  /// Checks if Ollama is running and the model is available
  static Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$OLLAMA_BASE_URL/api/tags'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final models = jsonResponse['models'] as List?;
        if (models != null) {
          return models.any((model) =>
              (model['name'] as String? ?? '').startsWith(VISION_MODEL));
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

