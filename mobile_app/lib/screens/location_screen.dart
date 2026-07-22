import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_status_colors.dart';
import '../controllers/location_controller.dart';
import '../models/emergency_contact_model.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late LocationController _controller;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _controller = LocationController();
    _controller.addListener(_onStateChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
      if (_controller.currentPosition != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_controller.currentPosition!.latitude, _controller.currentPosition!.longitude),
          ),
        );
      }
    }
  }

  void _toggleSharing() {
    if (_controller.state == LocationState.trackingActive) {
      _controller.stopLiveTracking();
    } else {
      _controller.startLiveTracking();
    }
  }

  void _copyCoordinates() {
    final pos = _controller.currentPosition;
    if (pos != null) {
      Clipboard.setData(ClipboardData(text: '${pos.latitude}, ${pos.longitude}'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
      ),
      body: SafeArea(
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_controller.state == LocationState.loading && _controller.currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.state == LocationState.permissionDenied) {
      return _buildErrorState(
        theme,
        icon: Icons.location_off_rounded,
        title: 'Permission Denied',
        message: 'Location permission is required to view and share your live location.',
        buttonText: 'Grant Permission',
        onPressed: _controller.initialize,
      );
    }

    if (_controller.state == LocationState.permissionPermanentlyDenied) {
      return _buildErrorState(
        theme,
        icon: Icons.settings_rounded,
        title: 'Permission Permanently Denied',
        message: 'Please enable location permissions in your device settings to continue.',
        buttonText: 'Open Settings',
        onPressed: _controller.openAppSettings,
      );
    }

    if (_controller.state == LocationState.gpsDisabled) {
      return _buildErrorState(
        theme,
        icon: Icons.gps_off_rounded,
        title: 'GPS Disabled',
        message: 'Your device location services are turned off. Please enable them to continue.',
        buttonText: 'Enable GPS',
        onPressed: _controller.openLocationSettings,
      );
    }
    
    if (_controller.state == LocationState.error) {
      return _buildErrorState(
        theme,
        icon: Icons.error_outline_rounded,
        title: 'Error',
        message: _controller.errorMessage ?? 'An unknown error occurred.',
        buttonText: 'Retry',
        onPressed: _controller.initialize,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share your location',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your trusted contacts informed of your real-time location.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildMapCard(theme),
          const SizedBox(height: 22),
          _buildCoordinatesCard(theme),
          const SizedBox(height: 22),
          _buildShareButton(theme),
          const SizedBox(height: 28),
          _buildTrustedContacts(theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, {required IconData icon, required String title, required String message, required String buttonText, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(ThemeData theme) {
    final pos = _controller.currentPosition;
    final bool hasLocation = pos != null;

    final String addressText = _controller.currentPlacemark != null
        ? '${_controller.currentPlacemark!.street}, ${_controller.currentPlacemark!.locality}'
        : (hasLocation ? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}' : 'Locating...');

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: hasLocation
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(pos.latitude, pos.longitude),
                      zoom: 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) => _mapController = controller,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_controller.state == LocationState.trackingActive)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Live',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: theme.extension<AppStatusColors>()?.sos ?? Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      addressText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              onPressed: () {
                if (pos != null && _mapController != null) {
                  _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
                }
              },
              backgroundColor: theme.colorScheme.surface,
              child: Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard(ThemeData theme) {
    final pos = _controller.currentPosition;
    final lat = pos?.latitude.toStringAsFixed(7) ?? '-';
    final lng = pos?.longitude.toStringAsFixed(7) ?? '-';
    final isLocating = _controller.state == LocationState.loading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Current Coordinates',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildCoordinateField('Latitude', lat, theme),
          const SizedBox(height: 14),
          _buildCoordinateField('Longitude', lng, theme),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLocating ? null : _controller.refreshLocation,
                  icon: isLocating 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.refresh),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: pos == null ? null : _copyCoordinates,
                icon: const Icon(Icons.content_copy_rounded),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: theme.dividerColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateField(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  Widget _buildShareButton(ThemeData theme) {
    final isSharing = _controller.state == LocationState.trackingActive;
    return ElevatedButton.icon(
      onPressed: _toggleSharing,
      icon: Icon(isSharing ? Icons.stop_circle_rounded : Icons.share_location_rounded),
      label: Text(isSharing ? 'Stop sharing' : 'Share location'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSharing ? (theme.extension<AppStatusColors>()?.sos ?? Colors.red) : (theme.extension<AppStatusColors>()?.success ?? Colors.green),
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 4,
      ),
    );
  }

  Widget _buildTrustedContacts(ThemeData theme) {
    final contacts = _controller.trustedContacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sharing with',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        if (contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No emergency contacts configured.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: contacts.map((contact) => _buildContactRow(contact, theme)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildContactRow(EmergencyContactModel contact, ThemeData theme) {
    final isSharing = _controller.state == LocationState.trackingActive;
    final initials = contact.displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      contact.relationship ?? 'Contact',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSharing ? 'Can see location' : 'Not sharing',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSharing ? (theme.extension<AppStatusColors>()?.success ?? Colors.green) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
