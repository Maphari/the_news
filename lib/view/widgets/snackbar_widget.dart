import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

enum MessageType { success, error, warning, info }

void showModernSnackBar(
  BuildContext context,
  String message, {
  MessageType type = MessageType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => ModernSnackBar(
      message: message,
      type: type,
      duration: duration,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  overlay.insert(overlayEntry);
}

class ModernSnackBar extends StatefulWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const ModernSnackBar({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<ModernSnackBar> createState() => _ModernSnackBarState();
}

class _ModernSnackBarState extends State<ModernSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF10B981).withValues(alpha: 0.15);
      case MessageType.error:
        return const Color(0xFFEF4444).withValues(alpha: 0.15);
      case MessageType.warning:
        return const Color(0xFFF59E0B).withValues(alpha: 0.15);
      case MessageType.info:
        return KAppColors.secondary.withValues(alpha: 0.15);
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF10B981);
      case MessageType.error:
        return const Color(0xFFEF4444);
      case MessageType.warning:
        return const Color(0xFFF59E0B);
      case MessageType.info:
        return KAppColors.secondary;
    }
  }

  Color _getIconColor() {
    return _getBorderColor();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_rounded;
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      case MessageType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                decoration: BoxDecoration(
                  color: KAppColors.onBackground.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getBorderColor().withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getBorderColor().withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getBackgroundColor(),
                            _getBackgroundColor().withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          //? Icon with gradient background
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getIconColor().withValues(alpha: 0.2),
                                  _getIconColor().withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getIconColor().withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _getIcon(),
                              color: _getIconColor(),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          //? Message
                          Expanded(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: KAppColors.darkSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          //? Close button
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: KAppColors.onSurface.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: KAppColors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}