import 'package:flutter/material.dart';
import 'dart:ui';

class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFullWidth;
  final bool isLoading;
  final bool isCompactMode; // Add this line

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFullWidth = false,
    this.isLoading = false,
    this.isCompactMode = false, // Add this line
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.isFullWidth ? 90 : (widget.isCompactMode ? 85 : 140), // Further reduced from 100 to 85
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(widget.isFullWidth ? 22 : (widget.isCompactMode ? 12 : 26)), // Reduced from 16 to 12
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
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
              child: widget.isFullWidth
                  ? _buildFullWidthContent()
                  : _buildCompactContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else
          Icon(
            widget.icon,
            size: 28,
            color: Colors.white,
          ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // Allow 2 lines for better text visibility
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContent() {
  // Use even smaller sizes for compact mode
  final iconSize = widget.isCompactMode ? 20.0 : 36.0; // Further reduced from 24 to 20
  final titleSize = widget.isCompactMode ? 14.0 : 18.0; // Reduced from 15 to 14
  final subtitleSize = widget.isCompactMode ? 10.0 : 13.0; // Reduced from 11 to 10
  final verticalSpacing = widget.isCompactMode ? 4.0 : 14.0; // Reduced from 6 to 4
  final titleSubtitleSpacing = widget.isCompactMode ? 1.0 : 4.0;

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.isLoading)
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        )
      else
        Icon(
          widget.icon,
          size: iconSize,
          color: Colors.white,
        ),
      SizedBox(height: verticalSpacing),
      Flexible( // Use Flexible instead of regular Text
        child: Text(
          widget.title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      SizedBox(height: titleSubtitleSpacing),
      Flexible( // Use Flexible for subtitle too
        child: Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: subtitleSize,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  );
}
}
