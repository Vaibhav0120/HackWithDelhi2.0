import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/glass_button.dart';
import 'image_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null && mounted) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ImagePreviewScreen(imagePath: pickedFile.path),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0E1A), // Deep space
              Color(0xFF1A1A2E), // Dark nebula
              Color(0xFF16213E), // Cosmic blue
              Color(0xFF0F3460), // Deep cosmic
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Space-themed App Title Section
                Column(
                  children: [
                    // Cosmic Icon with Glow Effect
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Space-themed Title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Colors.white,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'ToolFinder AI',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Space-themed Subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'AI-Powered Object Detection\nFrom the Depths of Space',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 3),
                
                // Enhanced Buttons Section
                Column(
                  children: [
                    // Take Photo Button
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: _isLoading ? () {} : () => _pickImage(ImageSource.camera),
                        icon: Icons.camera_alt_rounded,
                        title: 'Scan with Camera',
                        subtitle: 'Capture objects in real-time',
                        isFullWidth: true,
                        isLoading: _isLoading,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Select from Gallery Button
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: _isLoading ? () {} : () => _pickImage(ImageSource.gallery),
                        icon: Icons.photo_library_rounded,
                        title: 'Analyze from Gallery',
                        subtitle: 'Select existing image',
                        isFullWidth: true,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 2),
                
                // Space-themed Feature Cards
                _buildFeatureCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Neural Network Capabilities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(
                  Icons.local_fire_department_rounded,
                  'Fire Safety',
                  'Extinguishers',
                  Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureItem(
                  Icons.construction_rounded,
                  'Tool Storage',
                  'Toolboxes',
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureItem(
                  Icons.air_rounded,
                  'Life Support',
                  'Oxygen Tanks',
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}