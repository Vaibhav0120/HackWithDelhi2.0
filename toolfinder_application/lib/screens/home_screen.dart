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
              children: [
                // Top spacer
                const Spacer(flex: 2),
                
                // App Title
                Column(
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
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                // Middle spacer
                const Spacer(flex: 3),
                
                // Buttons section
                Column(
                  children: [
                    // Take Photo Button
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: () => _pickImage(context, ImageSource.camera),
                        icon: Icons.camera_alt,
                        title: 'Take Photo',
                        subtitle: 'Capture with camera',
                        isFullWidth: true,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Select from Gallery Button
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: () => _pickImage(context, ImageSource.gallery),
                        icon: Icons.photo_library,
                        title: 'Select from Gallery',
                        subtitle: 'Choose existing image',
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
                
                // Bottom spacer
                const Spacer(flex: 2),
                
                // Footer text
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Detects: Fire Extinguisher • Tool Box • Oxygen Tank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
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
