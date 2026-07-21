import 'package:dio/dio.dart';
import '../../models/audit_log.dart';
import 'audit_log_repository.dart';

/// Gerçek backend için HTTP audit log implementasyonu.
class HttpAuditLogRepository implements AuditLogRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpAuditLogRepository(this._dio);

  @override
  Future<List<AuditLog>> getLogs({
    AuditAction? action,
    bool? onlyRevertible,
  }) async {
    // TODO: GET /audit-logs?action=<action.code>&onlyRevertible=true|false
    // Yanıt: [{"_id": "...", "action": "PERMISSIONS_UPDATED", ...}]
    // AuditLog.fromJson ile dönüştür.
    throw UnimplementedError('HttpAuditLogRepository.getLogs');
  }

  @override
  Future<AuditLog> revertLog(String logId) async {
    // TODO: POST /audit-logs/:logId/revert
    // Backend orijinal işlemi geri alır ve yeni bir log kaydı döner.
    // Yanıt: yeni oluşturulan AuditLog JSON'ı
    throw UnimplementedError('HttpAuditLogRepository.revertLog');
  }
}
