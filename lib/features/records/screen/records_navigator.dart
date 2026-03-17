import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pet_model.dart';
import '../widgets/record_category.dart';
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

class RecordNavigationHelper {
  static void navigateToHistory({
    required BuildContext context,
    required WidgetRef ref,
    required RecordCategory category,
    required Pet pet,
    bool isAdd = false,
  }) {
    if (isAdd) {
      // Extract pet info for the new unified record model
      final pid = pet.petID;
      final name = pet.name;
      final type = pet.type;

      switch (category.label.toLowerCase()) {
        case 'medication':
          showAddMedicationDialog(context, pid, name, type);
          break;
        case 'vaccination':
          showAddVaccinationDialog(context, pid, name, type);
          break;
        case 'preventatives':
          showAddPreventativeDialog(context, pid, name, type);
          break;
        case 'vet visit':
          showAddVetVisitDialog(context, pid, name, type);
          break;
        case 'grooming':
          showAddGroomingDialog(context, pid, name, type);
          break;
        case 'weight':
          showAddWeightDialog(context, pid);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add ${category.label} coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return;
    }

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