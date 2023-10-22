class ConnectionTimeout implements Exception {}
class InvalidToken implements Exception {}
class WrongCredentials implements Exception {}

class CustomError implements Exception {
  final String message;
  //final bool loggedRequired;
  //final int errorCode;

  //CustomError(this.message, this.errorCode);
  //CustomError(this.message, [this.loggedRequired = false]);
  CustomError(this.message);
}