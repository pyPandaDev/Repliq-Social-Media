import 'package:get_storage/get_storage.dart';
import 'package:repliq/utils/storage/storage_key.dart';

class Storage {
  static final GetStorage session = GetStorage();

  // * Read user session
  static dynamic userSession = session.read(StorageKey.session);
}
