import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/audit_log.dart';
import '../../../core/providers/repository_providers.dart';

class AuditLogNotifier extends AsyncNotifier<List<AuditLog>> {
  AuditAction? _filterAction;
  bool _onlyRevertible = false;

  @override
  Future<List<AuditLog>> build() {
    return ref.read(auditLogRepositoryProvider).getLogs();
  }

  Future<void> refresh({
    AuditAction? action,
    bool? onlyRevertible,
  }) async {
    _filterAction = action;
    if (onlyRevertible != null) _onlyRevertible = onlyRevertible;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auditLogRepositoryProvider).getLogs(
            action: _filterAction,
            onlyRevertible: _onlyRevertible ? true : null,
          ),
    );
  }

  Future<void> revert(String logId) async {
    final newLog =
        await ref.read(auditLogRepositoryProvider).revertLog(logId);

    // Orijinal logu reverted olarak güncelle, yeni logu başa ekle
    final updated = (state.value ?? []).map((l) {
      if (l.id == logId) {
        return l.copyWith(
          isReverted: true,
          revertedAt: newLog.createdAt,
          revertedByName: newLog.performedByName,
        );
      }
      return l;
    }).toList();

    state = AsyncData([newLog, ...updated]);
  }
}

final auditLogProvider =
    AsyncNotifierProvider<AuditLogNotifier, List<AuditLog>>(
        AuditLogNotifier.new);
