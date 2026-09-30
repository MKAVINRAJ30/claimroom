import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime? expiresAt;
  final VoidCallback? onExpired;
  final TextStyle? style;

  const CountdownTimerWidget({
    super.key,
    required this.expiresAt,
    this.onExpired,
    this.style,
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
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    final formatted = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Text(
      formatted,
      style:
          widget.style ??
          const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFD97706),
          ),
    );
  }
}
