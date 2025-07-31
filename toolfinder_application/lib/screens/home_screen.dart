import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/glass_button.dart';
import 'image_preview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imagePath: pickedFile.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Title
                Container(
                  margin: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ToolFinder AI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Detect tools with AI-powered vision',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Take Photo Button
                GlassButton(
                  onPressed: () => _pickImage(context, ImageSource.camera),
                  icon: Icons.camera_alt,
                  title: 'Take Photo',
                  subtitle: 'Capture with camera',
                ),
                
                const SizedBox(height: 24),
                
                // Select from Gallery Button
                GlassButton(
                  onPressed: () => _pickImage(context, ImageSource.gallery),
                  icon: Icons.photo_library,
                  title: 'Select from Gallery',
                  subtitle: 'Choose existing image',
                ),
                
                const Spacer(),
                
                Text(
                  'Detects: Fire Extinguisher • Tool Box • Oxygen Tank',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
