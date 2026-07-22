import 'package:flutter/material.dart';

import '../services/alert_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LocationTrackingService {
  const LocationTrackingService._();

  static Future<void> stop() async {
    // Placeholder for the real tracking lifecycle integration.
  }
}

class AssistScreen extends StatefulWidget {
  const AssistScreen({
    super.key,
    required this.alertId,
  });

  final String alertId;

  @override
  State<AssistScreen> createState() => _AssistScreenState();
}

class _AssistScreenState extends State<AssistScreen> {
  bool _isEnding = false;

  Future<void> _endSos() async {
    if (_isEnding) return;

    setState(() => _isEnding = true);

    try {
      await LocationTrackingService.stop();
      await AlertService().resolveAlert(widget.alertId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SOS ended successfully.'),
          backgroundColor: Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to end SOS: $error'),
          backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASSIST ACTIVE'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: theme.extension<AppStatusColors>()?.success.withValues(alpha: 0.1) ?? Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: theme.extension<AppStatusColors>()?.success ?? Colors.green,
                  size: 78,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Emergency Activated',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your live location has been shared.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 14),
                    _StatusItem(text: 'Alert Created'),
                    SizedBox(height: 10),
                    _StatusItem(text: 'Location Shared'),
                    SizedBox(height: 10),
                    _StatusItem(text: 'Waiting for Response'),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isEnding ? null : _endSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.extension<AppStatusColors>()?.success ?? Colors.green,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEnding ? 'Ending SOS...' : 'End SOS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '•',
          style: TextStyle(
            color: Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
