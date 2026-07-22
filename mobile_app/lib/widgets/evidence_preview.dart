import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/evidence_model.dart';

class EvidencePreview extends StatefulWidget {
  final EvidenceModel evidence;

  const EvidencePreview({
    super.key,
    required this.evidence,
  });

  @override
  State<EvidencePreview> createState() => _EvidencePreviewState();
}

class _EvidencePreviewState extends State<EvidencePreview> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    if (widget.evidence.type == EvidenceType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(
      File(widget.evidence.filePath),
    );

    await _videoController!.initialize();

    if (!mounted) return;

    setState(() {
      _isVideoReady = true;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.evidence.type == EvidenceType.image) {
      return _buildImagePreview();
    }

    return _buildVideoPreview();
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        File(widget.evidence.filePath),
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoReady || _videoController == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),

          FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            onPressed: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

