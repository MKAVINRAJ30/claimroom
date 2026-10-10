import 'dart:async';
import 'package:flutter/material.dart';

/// Countdown timer that renders a circular progress ring around the seconds remaining.
/// The ring and text turn urgent red when fewer than 10 seconds remain.
class CountdownTimerWidget extends StatefulWidget {
  final DateTime? expiresAt;
  final VoidCallback? onExpired;
  final TextStyle? style;
  final double size;

  const CountdownTimerWidget({
    super.key,
    required this.expiresAt,
    this.onExpired,
    this.style,
    this.size = 48.0,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    if (widget.expiresAt == null) {
      if (_secondsLeft != 0) setState(() => _secondsLeft = 0);
      return;
    }

    final diff = widget.expiresAt!.difference(DateTime.now().toUtc()).inSeconds;
    if (diff <= 0) {
      if (_secondsLeft != 0) {
        setState(() => _secondsLeft = 0);
        widget.onExpired?.call();
      }
    } else {
      if (_secondsLeft != diff) {
        setState(() => _secondsLeft = diff);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_secondsLeft / 60.0).clamp(0.0, 1.0);
    final isUrgent = _secondsLeft < 10;
    final ringColor = isUrgent
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final trackColor = isUrgent
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);

    // Ensure minimum font size of 16px as mandated by accessibility and craft standards
    final customFontSize = widget.style?.fontSize;
    final effectiveFontSize = (customFontSize != null && customFontSize >= 16.0)
        ? customFontSize
        : 16.0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            backgroundColor: trackColor,
            strokeCap: StrokeCap.round,
          ),
          Text(
            '$_secondsLeft',
            style: (widget.style ?? const TextStyle()).copyWith(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.bold,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}
