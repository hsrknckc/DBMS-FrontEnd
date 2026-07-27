import '../../core/services/tcp_socket_service.dart';
import '../../models/audit_log.dart';
import 'audit_log_repository.dart';

/// TCP/IP soket üzerinden audit log sorgulama ve revert işlemleri.
///
/// Protokol aksiyonları:
///   auditLogs.list   → {action?, onlyRevertible?}
///   auditLogs.revert → {logId}
class TcpAuditLogRepository implements AuditLogRepository {
  final TcpSocketService _tcp;
  final String? Function() _tokenProvider;

  TcpAuditLogRepository(this._tcp, this._tokenProvider);

  @override
  Future<List<AuditLog>> getLogs({
    AuditAction? action,
    bool? onlyRevertible,
  }) async {
    final response = await _tcp.send(
      action: 'auditLogs.list',
      payload: {
        if (action != null) 'action': action.code,
        if (onlyRevertible != null) 'onlyRevertible': onlyRevertible,
      },
      token: _tokenProvider(),
    );
    final list =
        (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(AuditLog.fromJson).toList();
  }

  @override
  Future<AuditLog> revertLog(String logId) async {
    final response = await _tcp.send(
      action: 'auditLogs.revert',
      payload: {'logId': logId},
      token: _tokenProvider(),
    );
    return AuditLog.fromJson(response['data'] as Map<String, dynamic>);
  }
}
