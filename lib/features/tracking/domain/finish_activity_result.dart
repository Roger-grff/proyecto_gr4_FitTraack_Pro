import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/data/models/create_activity_result.dart';

class FinishActivityResult {
  final ActivitySession localSession;
  final CreateActivityResult backendResult;

  FinishActivityResult({
    required this.localSession,
    required this.backendResult,
  });
}
