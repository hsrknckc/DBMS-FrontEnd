enum Permission {
  databaseView,
  databaseCreate,

  dataView,
  dataCreate,
  dataUpdate,
  dataDelete,
  dataImport,
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

      case Permission.dataImport:
        return 'Veri içe aktarma';

      case Permission.dataExport:
        return 'Veri dışa aktarma';
    }
  }

  String get code {
    switch (this) {
      case Permission.databaseView:
        return 'DATABASE_VIEW';

      case Permission.databaseCreate:
        return 'DATABASE_CREATE';

      case Permission.dataView:
        return 'DATA_VIEW';

      case Permission.dataCreate:
        return 'DATA_CREATE';

      case Permission.dataUpdate:
        return 'DATA_UPDATE';

      case Permission.dataDelete:
        return 'DATA_DELETE';

      case Permission.dataImport:
        return 'DATA_IMPORT';

      case Permission.dataExport:
        return 'DATA_EXPORT';
    }
  }
}