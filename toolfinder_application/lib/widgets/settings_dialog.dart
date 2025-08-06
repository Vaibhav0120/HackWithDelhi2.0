import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _confidenceThreshold;
  late Map<String, bool> _enabledObjects;

  @override
  void initState() {
    super.initState();
    _confidenceThreshold = SettingsService.instance.confidenceThreshold;
    _enabledObjects = Map.from(SettingsService.instance.enabledObjects);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            // FIXED: Remove scrollable and set fixed constraints
            constraints: const BoxConstraints(
              maxHeight: 580,
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Detection Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // FIXED: Non-scrollable content with proper spacing
                // Confidence Threshold Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Confidence Threshold',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Current: ${(_confidenceThreshold * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Theme.of(context).colorScheme.secondary,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                          thumbColor: Theme.of(context).colorScheme.secondary,
                          overlayColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _confidenceThreshold,
                          min: 0.3,
                          max: 0.9,
                          divisions: 12,
                          onChanged: (value) {
                            setState(() {
                              _confidenceThreshold = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        'Higher = more accurate, fewer detections',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Object Selection Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Objects to Detect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // FIXED: Compact object toggles
                      ..._enabledObjects.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                SettingsService.instance.getObjectIcon(entry.key),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  SettingsService.instance.getDisplayName(entry.key),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: entry.value,
                                onChanged: (value) {
                                  setState(() {
                                    _enabledObjects[entry.key] = value;
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.secondary,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // FIXED: Working Save and Reset buttons with proper context handling
                Column(
                  children: [
                    // Save Button (Primary)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          // FIXED: Actually save the settings
                          await SettingsService.instance.setConfidenceThreshold(_confidenceThreshold);
                          for (final entry in _enabledObjects.entries) {
                            await SettingsService.instance.setObjectEnabled(entry.key, entry.value);
                          }
                          
                          // FIXED: Proper context handling
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            // Show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 12),
                                    Text('Settings saved successfully!'),
                                  ],
                                ),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Reset Button (Secondary)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () async {
                          // FIXED: Actually reset the settings
                          await SettingsService.instance.resetToDefaults();
                          if (context.mounted) {
                            setState(() {
                              _confidenceThreshold = SettingsService.instance.confidenceThreshold;
                              _enabledObjects = Map.from(SettingsService.instance.enabledObjects);
                            });
                            // Show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.refresh, color: Colors.white, size: 20),
                                    SizedBox(width: 12),
                                    Text('Settings reset to defaults'),
                                  ],
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Reset to Defaults',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
