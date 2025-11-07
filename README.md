# Image Analyzer App

A Flutter application that uses Ollama AI to analyze images and generate intelligent titles and descriptions. Simply select an image from your gallery or camera, and let AI describe what it sees.

## Features

- 📸 **Image Selection**: Pick images from gallery or take photos with camera
- 🤖 **AI-Powered Analysis**: Uses Ollama's LLaVA vision model to analyze images
- 📝 **Smart Descriptions**: Automatically generates concise titles and detailed descriptions
- 📋 **Easy Sharing**: Copy analysis results to clipboard with one tap
- 🎨 **Clean UI**: Modern, intuitive interface with Material Design

## Requirements

### Software
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Ollama installed on your computer
- LLaVA vision model (`llava:7b`)

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

**Note:** For permanent setup, create a launch agent or systemd service.

### 3. Download the Vision Model

```bash
ollama pull llava:7b
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

1. **Select an Image**
   - Tap "Gallery" to choose from your photo library
   - Tap "Camera" to take a new photo

2. **Analyze the Image**
   - Tap "Analyze Image with AI" button
   - Wait for AI analysis (typically 5-15 seconds)
   - View the generated title and description in a popup dialog

3. **Copy Results**
   - Tap "Copy" button in the dialog to copy the analysis to clipboard
   - Share or save the results as needed

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── upload_screen.dart   # Main screen with image selection and analysis
└── services/
    └── ollama_service.dart  # Service for interacting with Ollama API
```

## Dependencies

- `flutter`: Flutter SDK
- `http: ^1.5.0`: HTTP client for API calls
- `image_picker: ^1.2.0`: Image selection from gallery/camera
- `path_provider: ^2.1.5`: File path utilities

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
ollama pull llava:7b
```

### Slow analysis

- First analysis may be slower as the model loads
- Large images take longer to process
- Consider using a smaller/faster model like `llava:7b` (already configured)

## Configuration

### Using a Different Model

Edit `lib/services/ollama_service.dart`:
```dart
static const String VISION_MODEL = 'llava:13b'; // or other model
```

Available models:
- `llava:7b` - Fast, good quality (default)
- `llava:13b` - Slower, higher quality
- `llava:34b` - Slowest, best quality

### Changing Ollama Port

If Ollama runs on a different port:
1. Start Ollama with: `OLLAMA_HOST=0.0.0.0:CUSTOM_PORT ollama serve`
2. Update `OLLAMA_BASE_URL` in `ollama_service.dart`

## Privacy & Security

- **Local Processing**: Images are analyzed locally on your computer via Ollama
- **No Cloud Upload**: Images never leave your local network
- **Network Access**: Only your local network can access Ollama (configure firewall as needed)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available for personal and commercial use.

## Acknowledgments

- [Ollama](https://ollama.ai) for providing the AI inference engine
- [LLaVA](https://llava-vl.github.io/) for the vision-language model
