import 'package:bcrypt/bcrypt.dart';

void main() {
  final hashEmpty = '';
  try {
    print('Calling checkpw with empty hash...');
    final ok = BCrypt.checkpw('password', hashEmpty);
    print('Result: $ok');
  } catch (e) {
    print('Caught error as expected: $e');
  }
}
