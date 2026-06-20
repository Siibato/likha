import 'package:flutter/widgets.dart';

import 'package:likha/domain/tos/entities/tos_entity.dart';

/// Controller for the TOS detail page (desktop + mobile).
///
/// Owns all mutable form state and [TextEditingController]s used by the
/// add/edit competency and cell-override dialogs.
/// No [BuildContext] — pages show dialogs and read controller state.
class TosDetailController extends ChangeNotifier {
  final TextEditingController competencyController = TextEditingController();
  final TextEditingController timeUnitsTaughtController =
      TextEditingController();
  final TextEditingController cellOverrideController =
      TextEditingController();
  final TextEditingController editCompetencyController =
      TextEditingController();
  final TextEditingController editDaysTaughtController =
      TextEditingController();

  void prepareAddCompetency() {
    competencyController.clear();
    timeUnitsTaughtController.text = '1';
    notifyListeners();
  }

  void prepareEditCompetency(TosCompetency competency) {
    editCompetencyController.text = competency.competencyText;
    editDaysTaughtController.text = '${competency.timeUnitsTaught}';
    notifyListeners();
  }

  void prepareCellOverride(int? currentOverride) {
    cellOverrideController.text = currentOverride?.toString() ?? '';
    notifyListeners();
  }

  @override
  void dispose() {
    competencyController.dispose();
    timeUnitsTaughtController.dispose();
    cellOverrideController.dispose();
    editCompetencyController.dispose();
    editDaysTaughtController.dispose();
    super.dispose();
  }
}
