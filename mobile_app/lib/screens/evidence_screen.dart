import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evidence_model.dart';
import '../services/evidence_service.dart';
import '../theme/app_theme.dart';
import '../widgets/evidence_preview.dart';

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final EvidenceService _evidenceService = EvidenceService();
  final List<EvidenceModel> _evidenceList = [];
  bool _isLoading = false;

  Future<void> _capturePhoto() async {
    setState(() => _isLoading = true);

    try {
      final evidence = await _evidenceService.capturePhoto();

      if (evidence != null) {
        setState(() {
          _evidenceList.insert(0, evidence);
        });

        if (mounted) {
          _showSuccessSnackBar('Photo captured successfully.');
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recordVideo() async {
    setState(() => _isLoading = true);

    try {
      final evidence = await _evidenceService.recordVideo();

      if (evidence != null) {
        setState(() {
          _evidenceList.insert(0, evidence);
        });

        if (mounted) {
          _showSuccessSnackBar('Video recorded successfully.');
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvidence(EvidenceModel evidence) async {
    final shouldDelete = await _showDeleteConfirmation();
    if (!shouldDelete) return;

    try {
      await _evidenceService.deleteEvidence(evidence);

      setState(() {
        _evidenceList.remove(evidence);
      });

      if (mounted) {
        _showSuccessSnackBar('Evidence deleted successfully.');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Evidence?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(message),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Evidence Capture',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(36),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Store important emergency evidence securely on your device.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'captureEvidenceFab',
        backgroundColor: theme.extension<AppStatusColors>()?.sos ?? Colors.red,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Capture Evidence'),
        onPressed: _showCaptureOptions,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _evidenceList.isEmpty
                ? _buildEmptyState()
                : _buildEvidenceList(),
      ),
    );
  }

  void _showCaptureOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Capture Evidence',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text(
                    'Capture an image using your camera',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _capturePhoto();
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
                    child: Icon(
                      Icons.videocam,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: const Text('Record Video'),
                  subtitle: const Text(
                    'Record a short emergency video',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _recordVideo();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AppStatusColors>()?.sos.withValues(alpha: 0.1) ?? Colors.red.shade50,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Theme.of(context).extension<AppStatusColors>()?.sos.withValues(alpha: 0.3) ?? Colors.red.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 56,
                        color: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Evidence Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Capture photos or videos that may help during an emergency.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _showCaptureOptions,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture Evidence'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvidenceList() {
    return LayoutBuilder(
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _evidenceList.length,
              itemBuilder: (context, index) {
                final evidence = _evidenceList[index];
                return _buildEvidenceCard(evidence);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvidenceCard(EvidenceModel evidence) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: EvidencePreview(evidence: evidence),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<AppStatusColors>()?.sos.withValues(alpha: 0.1) ?? Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    evidence.type == EvidenceType.video
                        ? Icons.videocam
                        : Icons.photo,
                    color: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    evidence.type == EvidenceType.video ? 'Video' : 'Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _buildInfoTile(
              icon: Icons.insert_drive_file,
              title: 'File name',
              value: evidence.fileName,
            ),
            _buildInfoTile(
              icon: Icons.storage,
              title: 'File size',
              value: _formatFileSize(evidence.fileSize),
            ),
            _buildInfoTile(
              icon: Icons.calendar_today,
              title: 'Captured',
              value: DateFormat('dd MMM yyyy • hh:mm a').format(evidence.capturedAt),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () => _deleteEvidence(evidence),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
