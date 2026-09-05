import 'package:flutter/material.dart';

class UmkmHeader extends StatelessWidget {
  final String businessName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;

  const UmkmHeader({
    super.key,
    required this.businessName,
    this.avatarUrl,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? const Icon(Icons.person, color: Color(0xFF1B4F1E), size: 26)
              : null,
        ),
        const SizedBox(width: 12),
        // Greeting & Store Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang,',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                businessName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F1E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Notification Bell
        InkWell(
          onTap: onNotificationTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
