import 'package:flutter/material.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onCall;
  final VoidCallback onSms;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onSms,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withAlpha(15)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onCall,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 8),
                          _buildPrimaryBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.relationship != null && contact.relationship!.isNotEmpty
                          ? '${contact.relationship} • ${contact.formattedPhone}'
                          : contact.formattedPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildPopupMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE0E7FF),
      child: Text(
        contact.initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3730A3),
        ),
      ),
    );
  }

  Widget _buildPrimaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_rounded, size: 12, color: Color(0xFF3730A3)),
          SizedBox(width: 4),
          Text(
            'Primary',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3730A3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
      onSelected: (value) {
        switch (value) {
          case 'call':
            onCall();
            break;
          case 'sms':
            onSms();
            break;
          case 'primary':
            onSetPrimary();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'call',
          child: Row(
            children: [
              Icon(Icons.phone_rounded, size: 20),
              SizedBox(width: 12),
              Text('Call'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sms',
          child: Row(
            children: [
              Icon(Icons.message_rounded, size: 20),
              SizedBox(width: 12),
              Text('Send Message'),
            ],
          ),
        ),
        if (!contact.isPrimary)
          const PopupMenuItem(
            value: 'primary',
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 20),
                SizedBox(width: 12),
                Text('Set as Primary'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20),
              SizedBox(width: 12),
              Text('Edit Contact'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Text('Delete Contact', style: TextStyle(color: Colors.red.shade700)),
            ],
          ),
        ),
      ],
    );
  }
}
