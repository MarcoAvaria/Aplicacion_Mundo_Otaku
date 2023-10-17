
import '../entities/user.dart';

abstract class UserDatasource {
  
  Future<List<User>> getContactos({ int page = 1 });
}