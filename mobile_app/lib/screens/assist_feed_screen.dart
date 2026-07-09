import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/alert_service.dart';
import '../services/assist_service.dart'; // kDeveloperMode
import 'rescue_screen.dart';

class AssistFeedScreen extends StatelessWidget {
  const AssistFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AlertService alertService = AlertService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "ASSIST",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: alertService.getActiveAlerts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final docs = snapshot.data!.docs.where((doc) {
            if (!kDeveloperMode) {
              return true;
            }

            final data = doc.data() as Map<String, dynamic>;
            return data['userId'] == currentUserId;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Active Alerts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "SOS ALERT",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "📍 ${data["location"]}",
                        style:
                            const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "👤 ${data["userEmail"]}",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.volunteer_activism,
                          ),
                          label:
                              const Text("HELP NOW"),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFF16A34A),
                            foregroundColor:
                                Colors.white,
                          ),
                          onPressed: () async {
                            final alertId = docs[index].id;
                            final navigator = Navigator.of(context);

                            try {
                              if (!kDeveloperMode) {
                                await alertService.acceptAlert(
                                  alertId: alertId,
                                );
                              }

                              if (!navigator.mounted || !context.mounted) {
                                return;
                              }

                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => RescueScreen(
                                    alertId: alertId,
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not accept alert: $error',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}