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
  static const String OLLAMA_BASE_URL = 'http://10.253.123.162:11434';
  static const String VISION_MODEL = 'llava:7b'; // Using llava:7b model for image analysis

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

