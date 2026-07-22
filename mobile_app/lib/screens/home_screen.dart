import 'package:flutter/material.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'sos_screen.dart';
import 'location_screen.dart';
import 'emergency_contacts_screen.dart';
import 'assist_feed_screen.dart';
import 'journey_timer_screen.dart';
import 'evidence_screen.dart';
import 'unsafe_zone_map_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SafeStreet",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.waving_hand_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 26,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "Your safety network is active",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SosScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red,
                  shadowColor: (Theme.of(context).extension<AppStatusColors>()?.sos ?? Colors.red).withValues(alpha: 0.3),
                  elevation: 12,
                  shape: const CircleBorder(),
                  fixedSize: const Size(220, 220),
                ),
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white, // SOS button text is always white for contrast
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // Row 1
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    context,
                    Icons.volunteer_activism,
                    "ASSIST",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AssistFeedScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _actionCard(
                    context,
                    Icons.people,
                    "Contacts",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Row 2
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    context,
                    Icons.notifications,
                    "Alerts",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AlertsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _actionCard(
                    context,
                    Icons.timer,
                    "Journey",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const JourneyTimerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Row 3
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    context,
                    Icons.camera_alt,
                    "Camera",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EvidenceScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _actionCard(
                    context,
                    Icons.location_on,
                    "Location",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LocationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Row 4 — Community Map (Phase 12.1)
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    context,
                    Icons.map_rounded,
                    'Safe Map',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UnsafeZoneMapScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.shield,
                    color: Theme.of(context).extension<AppStatusColors>()?.success ?? Colors.green,
                    size: 40,
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      "Emergency protection is active",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AlertsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: "Alerts",
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  static Widget _actionCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,

        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 35,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
