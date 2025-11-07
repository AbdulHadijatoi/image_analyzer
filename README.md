# Ollama AI Features App

A comprehensive Flutter application showcasing the power of Ollama AI with multiple features including image analysis, chat, code generation, translation, summarization, and question answering. All processing happens locally on your computer - your data never leaves your network.

## Features

### 🎯 Core Features

- 📸 **Image Analyzer**: Analyze images and generate intelligent titles and descriptions using vision AI
- 💬 **AI Chat**: Have natural conversations with AI. Ask questions and get intelligent responses
- 💻 **Code Generation**: Generate code snippets, functions, and scripts in multiple programming languages
- 🌍 **Translation**: Translate text between 15+ languages with AI-powered accuracy
- 📝 **Text Summarization**: Summarize long texts, articles, and documents into concise summaries
- ❓ **Question Answering**: Ask questions and get detailed, accurate answers (with optional context)

### ✨ Key Highlights

- **Local Processing**: All AI processing happens locally on your computer via Ollama
- **No Cloud Upload**: Your data never leaves your local network
- **Privacy First**: Complete control over your data and AI models
- **Multiple Models**: Support for various Ollama models (LLaVA, Llama, Mistral, etc.)
- **Beautiful UI**: Modern, intuitive interface with Material Design
- **Easy Sharing**: Copy results to clipboard with one tap

## Requirements

### Software
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Ollama installed on your computer
- Vision model: `llava:7b` (for image analysis)
- Text model: `llama3.2` or similar (for text features)

### Network
- Your phone/device and computer must be on the same Wi-Fi network
- Ollama must be configured to listen on all network interfaces

## Setup Instructions

### 1. Install Ollama

**macOS:**
```bash
brew install ollama
```

**Other platforms:**
Visit [https://ollama.ai](https://ollama.ai) for installation instructions.

### 2. Start Ollama with Network Access

Ollama needs to be configured to accept connections from your phone. Run:

```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

**Note:** For permanent setup, create a launch agent or systemd service (see below).

### 3. Download Required Models

```bash
# Vision model for image analysis
ollama pull llava:7b

# Text model for other features (choose one or more)
ollama pull llama3.2        # Recommended: Fast and capable
# ollama pull llama2        # Alternative option
# ollama pull mistral       # Alternative option
```

### 4. Configure the App

1. Find your computer's IP address:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Windows
   ipconfig
   ```

2. Update `lib/services/ollama_service.dart`:
   ```dart
   static const String OLLAMA_BASE_URL = 'http://YOUR_COMPUTER_IP:11434';
   ```
   Replace `YOUR_COMPUTER_IP` with your actual IP address (e.g., `http://192.168.1.100:11434`)

### 5. Install Dependencies

```bash
flutter pub get
```

### 6. Run the App

```bash
flutter run
```

## How to Use

### Image Analyzer
1. Tap "Image Analyzer" from the home screen
2. Select an image from gallery or take a photo
3. Tap "Analyze Image with AI"
4. View the generated title and description
5. Copy results to clipboard

### AI Chat
1. Tap "AI Chat" from the home screen
2. Type your message and send
3. Have a conversation with AI
4. Clear chat history when needed

### Code Generation
1. Tap "Code Generation" from the home screen
2. Select programming language (or "any")
3. Describe what code you want
4. Tap "Generate Code"
5. Copy the generated code

### Translation
1. Tap "Translation" from the home screen
2. Enter text to translate
3. Select target language
4. Tap "Translate"
5. Copy translation or swap languages

### Text Summarization
1. Tap "Text Summarization" from the home screen
2. Paste or type text to summarize
3. Adjust max length slider (50-500 words)
4. Tap "Summarize"
5. Copy the summary

### Question Answering
1. Tap "Question Answering" from the home screen
2. Enter your question
3. (Optional) Provide context for more accurate answers
4. Tap "Get Answer"
5. Copy the answer

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── screens/
│   ├── home_screen.dart          # Home screen with feature list
│   ├── image_analyzer_screen.dart # Image analysis feature
│   ├── chat_screen.dart          # AI chat feature
│   ├── code_generation_screen.dart # Code generation feature
│   ├── translation_screen.dart   # Translation feature
│   ├── summarization_screen.dart # Text summarization feature
│   └── question_answering_screen.dart # Q&A feature
└── services/
    └── ollama_service.dart       # Service for Ollama API interactions
```

## Dependencies

- `flutter`: Flutter SDK
- `http: ^1.5.0`: HTTP client for API calls
- `image_picker: ^1.2.0`: Image selection from gallery/camera
- `path_provider: ^2.1.5`: File path utilities

## Configuration

### Using Different Models

Edit `lib/services/ollama_service.dart`:

```dart
// For vision tasks
static const String VISION_MODEL = 'llava:7b';

// For text tasks
static const String TEXT_MODEL = 'llama3.2'; // Change to llama2, mistral, etc.
```

### Available Models

**Vision Models:**
- `llava:7b` - Fast, good quality (default)
- `llava:13b` - Slower, higher quality
- `llava:34b` - Slowest, best quality

**Text Models:**
- `llama3.2` - Fast, capable (default, recommended)
- `llama2` - Good alternative
- `mistral` - Excellent for code
- `codellama` - Specialized for code generation
- `phi` - Small and fast

### Changing Ollama Port

If Ollama runs on a different port:
1. Start Ollama with: `OLLAMA_HOST=0.0.0.0:CUSTOM_PORT ollama serve`
2. Update `OLLAMA_BASE_URL` in `ollama_service.dart`

## Making Ollama Access Permanent

### macOS (Launch Agent)

Create `~/Library/LaunchAgents/com.ollama.server.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>0.0.0.0:11434</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Then load it:
```bash
launchctl load ~/Library/LaunchAgents/com.ollama.server.plist
```

### Linux (systemd)

Create `/etc/systemd/system/ollama.service`:

```ini
[Unit]
Description=Ollama Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0:11434"
Restart=always
User=ollama

[Install]
WantedBy=default.target
```

Then enable and start:
```bash
sudo systemctl enable ollama
sudo systemctl start ollama
```

## Troubleshooting

### Cannot connect to Ollama

1. **Check Ollama is running:**
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. **Verify network configuration:**
   - Ensure Ollama is listening on all interfaces: `lsof -i :11434`
   - Should show `*:11434` or `0.0.0.0:11434`, not just `localhost:11434`

3. **Check IP address:**
   - Make sure your computer's IP hasn't changed
   - Update `OLLAMA_BASE_URL` if needed

4. **Verify network:**
   - Phone and computer must be on the same Wi-Fi network
   - Firewall may be blocking connections (check port 11434)

### Model not found

If you see "model not found" error:
```bash
# For image analysis
ollama pull llava:7b

# For text features
ollama pull llama3.2
```

### Slow responses

- First request may be slower as the model loads
- Larger models are slower but more accurate
- Consider using smaller models for faster responses
- Image analysis takes longer than text generation

### Chat not maintaining context

The chat feature maintains conversation context automatically. If issues occur:
- Clear chat and start fresh
- Ensure you're using a compatible model (llama3.2, llama2, etc.)

## Privacy & Security

- **Local Processing**: All AI processing happens locally on your computer
- **No Cloud Upload**: Images and text never leave your local network
- **Network Access**: Only devices on your local network can access Ollama
- **Data Control**: You have complete control over your data and AI models
- **Firewall**: Configure your firewall to restrict access if needed

## Tips & Best Practices

1. **Model Selection**: Choose models based on your needs:
   - Fast responses: Use smaller models (llama3.2, llava:7b)
   - Better quality: Use larger models (llama3.1, llava:13b)

2. **Context in Q&A**: Providing context in question answering gives more accurate results

3. **Code Generation**: Be specific in your descriptions for better code generation

4. **Translation**: For best results, provide clear, well-formatted text

5. **Summarization**: Adjust the max length slider based on your needs

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available for personal and commercial use.

## Acknowledgments

- [Ollama](https://ollama.ai) for providing the AI inference engine
- [LLaVA](https://llava-vl.github.io/) for the vision-language model
- [Llama](https://llama.meta.com/) for the text generation models
- Flutter team for the amazing framework

## Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Available Models](https://ollama.ai/library)
- [Flutter Documentation](https://docs.flutter.dev/)

---

**Enjoy exploring the power of local AI with Ollama! 🚀**
