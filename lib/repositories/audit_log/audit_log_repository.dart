import '../../models/audit_log.dart';

/// Audit log sorgulama ve revert işlemleri için soyut arayüz.
abstract class AuditLogRepository {
  /// Audit logları getirir.
  /// [action] ile belirli bir işlem türüne filtre uygulanabilir.
  /// [onlyRevertible] true ise yalnızca geri alınabilir işlemler gelir.
  Future<List<AuditLog>> getLogs({
    AuditAction? action,
    bool? onlyRevertible,
  });

  /// Belirli bir audit log girişini geri alır.
  /// Backend'de ilgili işlemin tersi uygulanır ve yeni bir log oluşturulur.
  /// Dönen değer: geri alma işleminin yeni log kaydı.
  Future<AuditLog> revertLog(String logId);
}
