import 'package:flutter/material.dart';
import 'dart:ui';

class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFullWidth;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFullWidth = false,
    this.isLoading = false,
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
        height: widget.isFullWidth ? 80 : 120, // Increased height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
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
              padding: EdgeInsets.all(widget.isFullWidth ? 20 : 24), // Increased padding
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
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
          Container(
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
            size: 28, // Increased icon size
            color: Colors.white,
          ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18, // Increased font size
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14, // Increased font size
                  color: Colors.white.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          Container(
            width: 36,
            height: 36,
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
            size: 36, // Increased icon size
            color: Colors.white,
          ),
        const SizedBox(height: 16),
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18, // Increased font size
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 14, // Increased font size
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}