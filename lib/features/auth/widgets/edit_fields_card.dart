import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/account_controller.dart';

class EditFieldsCard extends ConsumerStatefulWidget {
  const EditFieldsCard({super.key});

  @override
  ConsumerState<EditFieldsCard> createState() => _EditFieldsCardState();
}

class _EditFieldsCardState extends ConsumerState<EditFieldsCard> {
  late TextEditingController _userController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(
        text: ref.read(authProvider).user?.username ?? "");
  }

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user?.username != previous?.user?.username) {
        _userController.text = next.user?.username ?? "";
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B947E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("USERNAME"),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _field(_userController, enabled: _isEditing)),
              const SizedBox(width: 8),
              if (!_isEditing)
                _iconBtn(Icons.edit_rounded, Colors.white70,
                    () => setState(() => _isEditing = true))
              else ...[
                _iconBtn(Icons.check_rounded, Colors.greenAccent, () {
                  ref.read(accountControllerProvider.notifier)
                      .saveUsername(_userController.text);
                  setState(() => _isEditing = false);
                }),
                const SizedBox(width: 4),
                _iconBtn(Icons.close_rounded, Colors.redAccent, () {
                  _userController.text = ref.read(authProvider).user?.username ?? "";
                  setState(() => _isEditing = false);
                }),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _label("EMAIL"),
          const SizedBox(height: 6),
          _field(TextEditingController(text: user?.email ?? ""), enabled: false, dimmed: true),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white70, fontSize: 11,
          fontWeight: FontWeight.bold, letterSpacing: 1.1));

  Widget _field(TextEditingController ctrl,
      {required bool enabled, bool dimmed = false}) =>
      SizedBox(
        height: 44,
        child: TextField(
          controller: ctrl,
          enabled: enabled,
          style: TextStyle(
              color: dimmed ? Colors.white60 : Colors.white, fontSize: 14),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: Colors.white.withOpacity(enabled ? 0.15 : 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}