enum Permission {
  databaseView,
  databaseCreate,
  dataView,
  dataCreate,
  dataUpdate,
  dataDelete,
  dataExport,
}

extension PermissionExtension on Permission {
  String get label {
    switch (this) {
      case Permission.databaseView:
        return 'Database görüntüleme';

      case Permission.databaseCreate:
        return 'Database oluşturma';

      case Permission.dataView:
        return 'Veri görüntüleme';

      case Permission.dataCreate:
        return 'Veri ekleme';

      case Permission.dataUpdate:
        return 'Veri güncelleme';

      case Permission.dataDelete:
        return 'Veri silme';

      case Permission.dataExport:
        return 'Veri dışa aktarma';
    }
  }
}