import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../widgets/record_category.dart';
import '../../records/theme/records_theme.dart';

// History screens
import '../../pets/screens/grooming_history_view.dart';
import '../../pets/screens/medication_history_view.dart';
import '../../pets/screens/weight_history_view.dart';
import '../../pets/screens/preventatives_history_view.dart';
import '../../pets/screens/vaccination_history_view.dart';
import '../../pets/screens/vet_visits_history_view.dart';
import '../../pets/screens/pet_profile_page.dart';

// Add dialogs
import '../../records/widgets/add_medication_dialog.dart';
import '../../records/widgets/add_vaccine_dialog.dart';
import '../../records/widgets/add_grooming_dialog.dart';
import '../../records/widgets/add_vet_visit_dialog.dart';
import '../../records/widgets/add_preventative_dialog.dart';
import '../../records/widgets/add_weight_dialog.dart';

// ─── Shared themed toast ──────────────────────────────────────────────────────

/// Call this after any record is saved successfully.
/// [isError] switches to a red/failure style.
void showRecordToast(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData icon = Icons.check_circle_outline_rounded,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isError
                ? const Color(0xFFB03A3A)
                : RecordsPalette.steel,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isError
                    ? const Color(0xFFB03A3A)
                    : RecordsPalette.steel).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
}

// ─── Navigation helper ────────────────────────────────────────────────────────

class RecordNavigationHelper {
  static void navigateToHistory({
    required BuildContext context,
    required WidgetRef ref,
    required RecordCategory category,
    required Pet pet,
    bool isAdd = false,
    // When true (quick add flow), pop all the way back to home after save
    bool popToHomeOnSave = false,
  }) {
    if (isAdd) {
      final pid  = pet.petID;
      final name = pet.name;
      final type = pet.type;

      // Callback fired after a successful save inside any add dialog
      void onSaved(String label) {
        if (popToHomeOnSave) {
          // Pop SelectPetDialog + any route on top, back to home
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          Navigator.of(context).pop(); // just close the dialog
        }
        showRecordToast(
          context,
          '$label saved for ${pet.name} 🐾',
          icon: Icons.check_circle_outline_rounded,
        );
      }

      switch (category.label.toLowerCase()) {
        case 'medication':
          showAddMedicationDialog(context, pid, name, type, onSaved: onSaved);
          break;
        case 'vaccination':
          showAddVaccinationDialog(context, pid, name, type, onSaved: onSaved);
          break;
        case 'preventatives':
          showAddPreventativeDialog(context, pid, name, type, onSaved: onSaved);
          break;
        case 'vet visit':
          showAddVetVisitDialog(context, pid, name, type, onSaved: onSaved);
          break;
        case 'grooming':
          showAddGroomingDialog(context, pid, name, type, onSaved: onSaved);
          break;
        case 'weight':
          showAddWeightDialog(context, pid, onSaved: () => onSaved('Weight'));
          break;
        default:
          showRecordToast(context, 'Add ${category.label} coming soon',
              isError: true);
      }
      return;
    }

    // ── Browse mode — push the history screen ─────────────────────────────
    final Widget destination = switch (category.label.toLowerCase()) {
      'grooming'      => GroomingHistoryView(pet: pet),
      'medication'    => MedicationHistoryView(pet: pet),
      'information'   => PetProfilePage(pet: pet),
      'weight'        => WeightHistoryView(pet: pet),
      'vaccination'   => VaccinationHistoryView(pet: pet),
      'preventatives' => PreventativesHistoryView(pet: pet),
      'vet visit'     => VetVisitsHistoryView(pet: pet),
      _               => Scaffold(appBar: AppBar(title: Text(category.label))),
    };

    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }
}