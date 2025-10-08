import 'package:flutter/material.dart';
import 'db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper.database;
  final users = await db.query('usuarios');
  print('Usuarios encontrados: ${users.length}');
  for (var u in users) {
    print('${u['email']} | ${u['senha']} | ${u['tipo']}');
  }
}
