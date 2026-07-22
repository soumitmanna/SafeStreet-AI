import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'settings_tile.dart';

class PermissionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Permission permission;

  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.permission,
  });

  @override
  State<PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends State<PermissionTile> with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission when app resumes in case user changed it in settings
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final status = await widget.permission.status;
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = PermissionStatus.permanentlyDenied;
        });
      }
    }
  }

  String _getStatusText() {
    if (_status == null) return 'Checking...';
    switch (_status!) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return 'Allowed';
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.provisional:
        return 'Denied';
    }
  }

  Color _getStatusColor(BuildContext context) {
    if (_status == PermissionStatus.granted || _status == PermissionStatus.limited) {
      return Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green.shade600;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Future<void> _handleTap() async {
    try {
      await openAppSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open system settings')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
      onTap: _handleTap,
    );
  }
}
