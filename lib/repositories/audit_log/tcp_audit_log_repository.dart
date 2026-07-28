import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/audit_log.dart';
import 'audit_log_repository.dart';

/// TCP/IP soket üzerinden audit log sorgulama ve revert işlemleri (Yeni Tek Protokol).
class TcpAuditLogRepository implements AuditLogRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  TcpAuditLogRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null) {
      throw const TcpException('Oturum açılmamış (kimlik bilgisi eksik).');
    }
    return c;
  }

  @override
  Future<List<AuditLog>> getLogs({
    AuditAction? action,
    bool? onlyRevertible,
  }) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'AUDIT_LOGS',
      username: c.username,
      password: c.password,
      filter: {
        if (action != null) 'action': action.code,
        if (onlyRevertible != null) 'onlyRevertible': onlyRevertible,
      },
    );

    final rawData = response['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }

    return rawData.map((item) {
      if (item is Map<String, dynamic>) return AuditLog.fromJson(item);
      if (item is Map) return AuditLog.fromJson(Map<String, dynamic>.from(item));
      return AuditLog(
        id: item.toString(),
        performedById: '',
        performedByName: '',
        action: AuditAction.databaseCreated,
        description: item.toString(),
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<AuditLog> revertLog(String logId) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'REVERT_AUDIT_LOG',
      username: c.username,
      password: c.password,
      filter: {'logId': logId},
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return AuditLog.fromJson(first);
      if (first is Map) return AuditLog.fromJson(Map<String, dynamic>.from(first));
    }

    return AuditLog(
      id: logId,
      performedById: '',
      performedByName: '',
      action: AuditAction.databaseCreated,
      description: 'Reverted $logId',
      createdAt: DateTime.now(),
    );
  }
}
