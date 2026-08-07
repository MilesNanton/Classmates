import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeMessageEntry;

enum MessageType { success, error }

void showMessagePopup(
  BuildContext context, {
  required String message,
  MessageType type = MessageType.success,
  Duration duration = const Duration(seconds: 3),
}) {
  showMessagePopupInOverlay(
    Overlay.of(context, rootOverlay: true),
    message: message,
    type: type,
    duration: duration,
  );
}

void showMessagePopupInOverlay(
  OverlayState overlay, {
  required String message,
  MessageType type = MessageType.success,
  Duration duration = const Duration(seconds: 3),
}) {
  _activeMessageEntry?.remove();
  _activeMessageEntry = null;
  late final OverlayEntry entry;

  void removeEntry() {
    if (entry.mounted) entry.remove();
    if (identical(_activeMessageEntry, entry)) _activeMessageEntry = null;
  }

  entry = OverlayEntry(
    builder: (_) => MessageWidget(
      message: message,
      type: type,
      duration: duration,
      onDismissed: removeEntry,
    ),
  );

  _activeMessageEntry = entry;
  overlay.insert(entry);
}

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    super.key,
    required this.message,
    this.type = MessageType.success,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onDismissed;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.type == MessageType.error;
    final accentColor = isError
        ? const Color(0xFFD92D20)
        : const Color(0xFF16835B);

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _controller,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: .18)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isError
                              ? Icons.error_outline_rounded
                              : Icons.check_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFF1D2939),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _dismiss,
                        tooltip: 'Dismiss',
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF667085),
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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
