import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../services/ollama_service.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  File? _originalImage;
  File? _editedImage;
  Uint8List? _imageBytes;
  String? _originalFormat; // 'jpg', 'png', etc.
  bool _isProcessing = false;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  int _rotation = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _originalImage = File(image.path);
          _editedImage = null;
          _resetAdjustments();
          _loadImageBytes();
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _loadImageBytes() async {
    if (_originalImage != null) {
      final bytes = await _originalImage!.readAsBytes();
      // Detect image format
      final extension = _originalImage!.path.split('.').last.toLowerCase();
      setState(() {
        _imageBytes = bytes;
        _originalFormat = extension == 'jpg' || extension == 'jpeg' ? 'jpg' : 'png';
      });
    }
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _rotation = 0;
      _flipHorizontal = false;
      _flipVertical = false;
      _editedImage = null;
      _imageBytes = null;
      _originalFormat = null;
    });
    if (_originalImage != null) {
      _loadImageBytes();
    }
  }

  Future<void> _applyEdits() async {
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Decode image
      img.Image? image = img.decodeImage(_imageBytes!);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply rotation
      if (_rotation != 0) {
        image = img.copyRotate(image, angle: _rotation.toDouble());
      }

      // Apply flips
      if (_flipHorizontal) {
        image = img.flipHorizontal(image);
      }
      if (_flipVertical) {
        image = img.flipVertical(image);
      }

      // Apply brightness, contrast, saturation
      if (_brightness != 0.0 || _contrast != 1.0 || _saturation != 1.0) {
        image = img.adjustColor(
          image,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
        );
      }

      // Encode and save (preserve format if possible)
      Uint8List editedBytes;
      String fileExtension;
      if (_originalFormat == 'jpg') {
        editedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
        fileExtension = 'jpg';
      } else {
        editedBytes = Uint8List.fromList(img.encodePng(image));
        fileExtension = 'png';
      }
      final tempDir = await getTemporaryDirectory();
      final editedFile = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      await editedFile.writeAsBytes(editedBytes);

      setState(() {
        _editedImage = editedFile;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error applying edits: $e');
    }
  }

  Future<void> _resizeImage(int width, int height) async {
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      img.Image? image = img.decodeImage(_imageBytes!);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      image = img.copyResize(image, width: width, height: height);

      // Preserve format
      Uint8List resizedBytes;
      String fileExtension;
      if (_originalFormat == 'jpg') {
        resizedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
        fileExtension = 'jpg';
      } else {
        resizedBytes = Uint8List.fromList(img.encodePng(image));
        fileExtension = 'png';
      }
      final tempDir = await getTemporaryDirectory();
      final resizedFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      await resizedFile.writeAsBytes(resizedBytes);

      setState(() {
        _editedImage = resizedFile;
        _imageBytes = resizedBytes;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error resizing image: $e');
    }
  }

  Future<void> _cropImage(int width, int height) async {
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      img.Image? image = img.decodeImage(_imageBytes!);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Center crop
      final origWidth = image.width;
      final origHeight = image.height;
      
      // Calculate crop region (center crop)
      final cropX = (origWidth - width) ~/ 2;
      final cropY = (origHeight - height) ~/ 2;
      
      // Ensure crop region is within bounds
      final x = cropX < 0 ? 0 : cropX;
      final y = cropY < 0 ? 0 : cropY;
      final w = width > origWidth ? origWidth : width;
      final h = height > origHeight ? origHeight : height;

      image = img.copyCrop(image, x: x, y: y, width: w, height: h);

      // Preserve format
      Uint8List croppedBytes;
      String fileExtension;
      if (_originalFormat == 'jpg') {
        croppedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
        fileExtension = 'jpg';
      } else {
        croppedBytes = Uint8List.fromList(img.encodePng(image));
        fileExtension = 'png';
      }
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      await croppedFile.writeAsBytes(croppedBytes);

      setState(() {
        _editedImage = croppedFile;
        _imageBytes = croppedBytes;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error cropping image: $e');
    }
  }

  Future<void> _analyzeEditedImage() async {
    final imageToAnalyze = _editedImage ?? _originalImage;
    if (imageToAnalyze == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final description = await OllamaService.describeImage(imageToAnalyze);
      
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        _showAnalysisDialog(description);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error analyzing image: $e');
    }
  }

  void _showAnalysisDialog(ImageDescription description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue),
            SizedBox(width: 8),
            Text('Image Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Title:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description.title),
              const SizedBox(height: 16),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showCustomResizeDialog() {
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Resize'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Width (pixels)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Height (pixels)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final width = int.tryParse(widthController.text);
              final height = int.tryParse(heightController.text);
              if (width != null && height != null && width > 0 && height > 0) {
                Navigator.of(context).pop();
                _resizeImage(width, height);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid dimensions')),
                );
              }
            },
            child: const Text('Resize'),
          ),
        ],
      ),
    );
  }

  void _showCustomCropDialog() {
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Crop from center', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Crop Width (pixels)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Crop Height (pixels)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final width = int.tryParse(widthController.text);
              final height = int.tryParse(heightController.text);
              if (width != null && height != null && width > 0 && height > 0) {
                Navigator.of(context).pop();
                _cropImage(width, height);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid dimensions')),
                );
              }
            },
            child: const Text('Crop'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage() async {
    final imageToSave = _editedImage ?? _originalImage;
    if (imageToSave == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = imageToSave.path.split('.').last;
      final fileName = 'edited_image_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final savedFile = await imageToSave.copy('${directory.path}/$fileName');
      
      await Clipboard.setData(ClipboardData(text: savedFile.path));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved! Path copied to clipboard')),
        );
      }
    } catch (e) {
      _showError('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        actions: [
          if (_originalImage != null)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _isProcessing ? null : _analyzeEditedImage,
              tooltip: 'Analyze with AI',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : (_editedImage != null || _originalImage != null)
                        ? Image.file(
                            _editedImage ?? _originalImage!,
                            fit: BoxFit.contain,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No image selected',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Image Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_originalImage != null) ...[
              // Resize Section
              const Text('Resize:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResizeButton(label: 'Small (640x480)', width: 640, height: 480, onTap: _resizeImage),
                  _ResizeButton(label: 'Medium (1024x768)', width: 1024, height: 768, onTap: _resizeImage),
                  _ResizeButton(label: 'Large (1920x1080)', width: 1920, height: 1080, onTap: _resizeImage),
                  _ResizeButton(label: 'Square (512x512)', width: 512, height: 512, onTap: _resizeImage),
                  _ResizeButton(label: 'Thumbnail (256x256)', width: 256, height: 256, onTap: _resizeImage),
                  _ResizeButton(label: 'HD (1280x720)', width: 1280, height: 720, onTap: _resizeImage),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _showCustomResizeDialog,
                      icon: const Icon(Icons.aspect_ratio),
                      label: const Text('Custom Resize'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _showCustomCropDialog,
                      icon: const Icon(Icons.crop),
                      label: const Text('Crop'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rotation & Flip
              const Text('Rotation & Flip:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () {
                        setState(() {
                          _rotation = (_rotation + 90) % 360;
                        });
                        _applyEdits();
                      },
                      icon: const Icon(Icons.rotate_right),
                      label: const Text('Rotate 90°'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () {
                        setState(() {
                          _flipHorizontal = !_flipHorizontal;
                        });
                        _applyEdits();
                      },
                      icon: const Icon(Icons.flip),
                      label: const Text('Flip H'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () {
                        setState(() {
                          _flipVertical = !_flipVertical;
                        });
                        _applyEdits();
                      },
                      icon: const Icon(Icons.flip),
                      label: const Text('Flip V'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Adjustments
              const Text('Adjustments:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Brightness
              Row(
                children: [
                  const SizedBox(width: 100, child: Text('Brightness:')),
                  Expanded(
                    child: Slider(
                      value: _brightness,
                      min: -1.0,
                      max: 1.0,
                      divisions: 20,
                      label: _brightness.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          _brightness = value;
                        });
                      },
                      onChangeEnd: (_) => _applyEdits(),
                    ),
                  ),
                ],
              ),

              // Contrast
              Row(
                children: [
                  const SizedBox(width: 100, child: Text('Contrast:')),
                  Expanded(
                    child: Slider(
                      value: _contrast,
                      min: 0.0,
                      max: 2.0,
                      divisions: 20,
                      label: _contrast.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          _contrast = value;
                        });
                      },
                      onChangeEnd: (_) => _applyEdits(),
                    ),
                  ),
                ],
              ),

              // Saturation
              Row(
                children: [
                  const SizedBox(width: 100, child: Text('Saturation:')),
                  Expanded(
                    child: Slider(
                      value: _saturation,
                      min: 0.0,
                      max: 2.0,
                      divisions: 20,
                      label: _saturation.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() {
                          _saturation = value;
                        });
                      },
                      onChangeEnd: (_) => _applyEdits(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () {
                        _resetAdjustments();
                        setState(() {
                          _editedImage = null;
                          _imageBytes = null;
                        });
                        _loadImageBytes();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing || _editedImage == null ? null : _saveImage,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResizeButton extends StatelessWidget {
  final String label;
  final int width;
  final int height;
  final Function(int, int) onTap;

  const _ResizeButton({
    required this.label,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onTap(width, height),
      child: Text(label),
    );
  }
}

