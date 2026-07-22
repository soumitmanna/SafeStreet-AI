import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/evidence_model.dart';
import '../models/emergency_contact_model.dart';
import '../services/emergency_contact_service.dart';
import '../services/evidence_service.dart';
import '../services/sos_service.dart';
import 'assist_screen.dart';
import 'emergency_contacts_screen.dart';
import '../theme/app_theme.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final SosService _sosService = SosService();
  final EvidenceService _evidenceService = EvidenceService();
  final EmergencyContactService _contactService = EmergencyContactService();

  bool _emergencyActive = false;
  bool _isSending = false;
  bool _alertCreated = false;
  bool _isLoadingContacts = true;
  String _status = 'Ready to help';
  String _location = 'Waiting for SOS activation';
  String? _mapsLink;
  EvidenceModel? _selectedEvidence;
  List<EmergencyContactModel> _contacts = const [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _confirmEmergency() async {
    final shouldActivate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Emergency'),
          content: const Text(
            'Emergency mode will activate in 3 seconds.\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Activate'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (shouldActivate == true) {
      await _activateEmergency();
    }
  }

  Future<void> _activateEmergency() async {
    setState(() {
      _isSending = true;
      _alertCreated = false;
      _status = 'Sending SOS alert...';
    });

    try {
      final evidence = await _requestEvidenceAttachment();
      if (!mounted) return;

      setState(() {
        _selectedEvidence = evidence;
        _mapsLink = null;
      });

      final result = await _sosService.createActiveAlert(evidence: evidence);

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _emergencyActive = true;
        _alertCreated = true;
        _status = 'Emergency Active';
        _location = result.location;
        _mapsLink = 'https://www.google.com/maps/search/?api=1&query=${result.latitude},${result.longitude}';
      });

      String snackMessage = 'SOS alert created successfully.';
      if (result.contactsNotified > 0 && result.smsFailedCount > 0) {
        snackMessage =
            'SOS alert created successfully. ${result.contactsNotified} contact(s) notified; ${result.smsFailedCount} could not be notified.';
      } else if (result.contactsNotified == 0) {
        snackMessage = 'SOS alert created successfully. No trusted contacts were available.';
      }

      _showSnackBar(snackMessage, backgroundColor: Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green);

      await Future<void>.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AssistScreen(alertId: result.alertId),
        ),
      );
    } on SosException catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _alertCreated = false;
        _status = 'Ready to help';
      });

      _showSnackBar(error.message, backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _alertCreated = false;
        _status = 'Ready to help';
      });

      _showSnackBar('SOS failed: $error', backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red);
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactService.getContactsForSOS();
      if (!mounted) return;

      setState(() {
        _contacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _contacts = const [];
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _refreshLocation() async {
    try {
      final locationInfo = await _sosService.resolveCurrentLocation();
      if (!mounted) return;

      setState(() {
        _location = locationInfo.location;
        _mapsLink = locationInfo.mapsLink;
      });

      _showSnackBar('Location updated.', backgroundColor: Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString(), backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red);
    }
  }

  Future<void> _openMapView() async {
    final mapsLink = _mapsLink;
    if (mapsLink == null || mapsLink.isEmpty) {
      _showSnackBar('Location not available yet.', backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red);
      return;
    }

    final uri = Uri.parse(mapsLink);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      _showSnackBar('Could not open maps.', backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red);
    }
  }

  Future<EvidenceModel?> _requestEvidenceAttachment() async {
    while (mounted) {
      if (!mounted) return null;
      final action = await showModalBottomSheet<_EvidenceOption>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Attach Evidence (Optional)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Adding a photo or short video may help responders understand your situation.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(_EvidenceOption.photo),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(_EvidenceOption.video),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record Video'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(_EvidenceOption.skip),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || action == _EvidenceOption.skip || action == null) {
        if (!mounted) return null;
        _showSnackBar(
          'Continuing without evidence.',
          backgroundColor: Theme.of(context).colorScheme.primary,
        );
        return null;
      }

      final evidence = await _captureEvidence(action);
      if (evidence != null) {
        return evidence;
      }
    }

    return null;
  }

  Future<EvidenceModel?> _captureEvidence(_EvidenceOption action) async {
    try {
      final EvidenceModel? evidence;
      if (action == _EvidenceOption.photo) {
        evidence = await _evidenceService.capturePhoto();
      } else {
        evidence = await _evidenceService.recordVideo();
      }

      if (evidence == null) {
        return null;
      }

      if (!mounted) return null;
      setState(() {
        _selectedEvidence = evidence;
      });
      _showSnackBar(
        action == _EvidenceOption.photo
            ? 'Photo attached successfully.'
            : 'Video attached successfully.',
        backgroundColor: Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green,
        context: context,
      );

      return evidence;
    } catch (error) {
      if (!mounted) return null;
      _showSnackBar(
        'Something went wrong while capturing evidence.',
        backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
        context: context,
      );
      return null;
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor, BuildContext? context}) {
    final messengerContext = context ?? this.context;
    ScaffoldMessenger.of(messengerContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 24),
                    if (_selectedEvidence != null) _buildEvidencePreviewCard(theme),
                    if (_selectedEvidence != null) const SizedBox(height: 16),
                    if (isWide) _buildWideLayout(theme) else _buildNarrowLayout(theme),
                    const SizedBox(height: 18),
                    _buildAlertCreatedBanner(theme),
                    const SizedBox(height: 24),
                    _buildLiveLocationCard(theme),
                    const SizedBox(height: 18),
                    _buildEmergencyContactsCard(theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay safe, stay ready',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One tap alert for your trusted contacts and responders.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildStatusCard(theme)),
        const SizedBox(width: 18),
        Expanded(child: _buildSOSButton(theme, height: 360)),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSOSButton(theme),
        const SizedBox(height: 20),
        _buildStatusCard(theme),
      ],
    );
  }

  Widget _buildEvidencePreviewCard(ThemeData theme) {
    final evidence = _selectedEvidence;
    if (evidence == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 62,
              height: 62,
              child: evidence.type == EvidenceType.image
                  ? Image.file(
                      File(evidence.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined),
                    )
                  : Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.play_circle_fill, color: theme.colorScheme.primary, size: 30),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.type == EvidenceType.image ? 'Photo attached' : 'Video attached',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  evidence.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedEvidence = null;
              });
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(ThemeData theme, {double height = 320}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.extension<AppStatusColors>()?.sos.withValues(alpha: 0.1) ?? Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.extension<AppStatusColors>()?.sos.withValues(alpha: 0.12) ?? const Color.fromRGBO(244, 67, 54, 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: ElevatedButton(
            onPressed: _isSending ? null : _confirmEmergency,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSending ? theme.colorScheme.onSurfaceVariant : (theme.extension<AppStatusColors>()?.sos ?? Colors.red),
              disabledBackgroundColor: theme.colorScheme.onSurfaceVariant,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: theme.extension<AppStatusColors>()?.sos.withValues(alpha: 0.35) ?? const Color.fromRGBO(255, 82, 82, 0.35),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSending)
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.surface,
                      strokeWidth: 5,
                    ),
                  )
                else
                  Text(
                    'SOS',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _isSending
                      ? 'Sharing location'
                      : _emergencyActive
                          ? 'Alert active'
                          : 'Tap to send alert',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCreatedBanner(ThemeData theme) {
    return AnimatedOpacity(
      opacity: _alertCreated ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      child: AnimatedScale(
        scale: _alertCreated ? 1 : 0.96,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: IgnorePointer(
          ignoring: !_alertCreated,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.extension<AppStatusColors>()?.success.withValues(alpha: 0.1) ?? Colors.green.shade50,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.extension<AppStatusColors>()?.success.withValues(alpha: 0.3) ?? Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.extension<AppStatusColors>()?.success ?? Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: theme.colorScheme.onPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert Created',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.extension<AppStatusColors>()?.success ?? Colors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedEvidence != null
                            ? 'SOS alert created with evidence attached.'
                            : 'SOS alert created successfully.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.extension<AppStatusColors>()?.success ?? Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
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
                  color: _emergencyActive ? (theme.extension<AppStatusColors>()?.sos.withValues(alpha: 0.1) ?? Colors.red.shade50) : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _emergencyActive ? Icons.warning_amber_rounded : Icons.health_and_safety_rounded,
                  color: _emergencyActive ? (theme.extension<AppStatusColors>()?.sos ?? Colors.red) : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _status,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Current emergency state, alerts sent to your saved contacts, and estimated response readiness.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 22),
          _buildStatusDetail(theme, 'Firestore alert', _emergencyActive ? 'Created' : 'Not sent'),
          const SizedBox(height: 14),
          _buildStatusDetail(theme,
            'Response status',
            _isSending
                ? 'Getting location'
                : _emergencyActive
                    ? 'Awaiting confirmation'
                    : 'Ready to activate',
          ),
          const SizedBox(height: 14),
          _buildStatusDetail(theme, 'Last update', 'Just now'),
        ],
      ),
    );
  }

  Widget _buildStatusDetail(ThemeData theme, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLiveLocationCard(ThemeData theme) {
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
              Icon(Icons.location_on, color: theme.extension<AppStatusColors>()?.sos ?? Colors.red),
              const SizedBox(width: 10),
              Text('Live location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Latitude / Longitude',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            _location,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _refreshLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _openMapView,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: const Text('Map view'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(ThemeData theme) {
    final contacts = _contacts;

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
              Icon(Icons.person_pin_circle_rounded, color: theme.colorScheme.onSurface),
              const SizedBox(width: 10),
              Text('Emergency contacts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingContacts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Loading contacts...'),
            )
          else if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No trusted contacts added.'),
            )
          else
            ...contacts.map((contact) {
              final name = contact.displayName;
              final relation = contact.relationship ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        contact.initials,
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (contact.isPrimary) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.star_rounded, size: 14, color: theme.colorScheme.primary),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(relation.isEmpty ? 'Trusted contact' : relation, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _contactService.smsContact(contact).catchError((_) {});
                      },
                      icon: Icon(Icons.message_rounded, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSurface,
              foregroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Manage contacts', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _EvidenceOption {
  photo,
  video,
  skip,
}
