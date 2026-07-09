import 'dart:async';
import 'package:flutter/material.dart';

import '../services/sos_service.dart';
import 'assist_screen.dart';

class JourneyTimerScreen extends StatefulWidget {
  const JourneyTimerScreen({super.key});

  @override
  State<JourneyTimerScreen> createState() =>
      _JourneyTimerScreenState();
}

class _JourneyTimerScreenState extends State<JourneyTimerScreen> {
  Duration _remainingTime = Duration.zero;

  Timer? _timer;

  bool _isRunning = false;

  final SosService _sosService = SosService();

  final TextEditingController _hoursController =
      TextEditingController();

  final TextEditingController _minutesController =
      TextEditingController();

  void _startCustomTimer() {
    final hours =
        int.tryParse(_hoursController.text.trim()) ?? 0;

    final minutes =
        int.tryParse(_minutesController.text.trim()) ?? 0;

    if (hours == 0 && minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid duration.",
          ),
        ),
      );
      return;
    }

    _startTimer(hours * 60 + minutes);
  }

  void _startTimer(int totalMinutes) {
    _timer?.cancel();

    setState(() {
      _remainingTime = Duration(minutes: totalMinutes);
      _isRunning = true;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (_remainingTime.inSeconds <= 1) {
          timer.cancel();

          setState(() {
            _remainingTime = Duration.zero;
            _isRunning = false;
          });

          try {
            final result =
                await _sosService.createActiveAlert();

            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssistScreen(
                  alertId: result.alertId,
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Failed to trigger SOS: $e",
                ),
              ),
            );
          }

          return;
        }

        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();

    setState(() {
      _remainingTime = Duration.zero;
      _isRunning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Journey completed safely ✅",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _hoursController.dispose();
    _minutesController.dispose();

    super.dispose();
  }

  String get _formattedTime {
    final hours = _remainingTime.inHours;
    final minutes =
        _remainingTime.inMinutes.remainder(60);
    final seconds =
        _remainingTime.inSeconds.remainder(60);

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Journey Timer",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            const Text(
              "Set Journey Duration",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Hours",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Minutes",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _startCustomTimer,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  "Start Journey",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const Spacer(),

            if (_isRunning)
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _stopTimer,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    "Stop Journey Safely",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}