import 'package:flutter/material.dart';

class ActionsCard extends StatelessWidget {
  final VoidCallback? onChangePassword;
  final VoidCallback onArchive;
  final VoidCallback onLogout;

  const ActionsCard({
    super.key,
    required this.onChangePassword,
    required this.onArchive,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B947E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _tile(Icons.lock_outline_rounded, "Change Password", onChangePassword,
              disabled: onChangePassword == null),
          _divider(),
          _tile(Icons.archive_outlined, "Archived Pets", onArchive),
          _divider(),
          _tile(Icons.logout_rounded, "Logout", onLogout,
              color: const Color(0xFF7B2B2B)),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback? onTap,
      {Color? color, bool disabled = false}) =>
      InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon,
                  color: disabled
                      ? Colors.white24
                      : (color ?? Colors.white70),
                  size: 20),
              const SizedBox(width: 14),
              Text(label,
                  style: TextStyle(
                      color: disabled
                          ? Colors.white24
                          : (color ?? Colors.white),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: disabled
                      ? Colors.white12
                      : (color?.withOpacity(0.6) ?? Colors.white38),
                  size: 18),
            ],
          ),
        ),
      );

  Widget _divider() =>
      Divider(color: Colors.white.withOpacity(0.1), height: 1);
}