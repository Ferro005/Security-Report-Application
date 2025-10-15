import 'dart:async';
import 'package:bcrypt/bcrypt.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import 'auditoria_service.dart';

class AuthService {
  /// Gera hash seguro para nova password (com sal e custo configurável)
  static String hashPassword(String senha, {int rounds = 12}) {
    try {
      // BCrypt.gensalt() não aceita parâmetros na versão atual
      final salt = BCrypt.gensalt();
      return BCrypt.hashpw(senha, salt);
    } catch (e) {
      throw Exception('Erro ao gerar hash da senha: $e');
    }
  }

  /// Cria um novo usuário com senha hasheada
  static Future<bool> criarUsuario(String nome, String email, String senha) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Verificar se email já existe
      final existe = await db.query(
        'usuarios',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (existe.isNotEmpty) {
        throw Exception('Email já cadastrado');
      }

      // Gerar hash da senha
      final hash = hashPassword(senha);

      // Inserir novo usuário
      await db.insert('usuarios', {
        'nome': nome,
        'email': email,
        'hash': hash,
        'tipo': 'usuario', // novos usuários são sempre do tipo 'usuario'
        'failed_attempts': 0,
        'last_failed_at': null,
        'locked_until': null,
      });

      await AuditoriaService.registar(
        acao: 'criar_usuario',
        detalhe: 'Novo usuário criado: $email'
      );

      return true;
    } catch (e) {
      print('Erro ao criar usuário: $e');
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  /// Tenta login com bloqueio temporário e logs de auditoria
  static Future<User?> login(String email, String senha) async {
    try {
        final db = await DatabaseHelper.instance.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Buscar usuário
        final rows = await db.query(
            'usuarios',
            where: 'email = ?',
            whereArgs: [email],
            limit: 1,
        );

        if (rows.isEmpty) {
            await AuditoriaService.registar(
                acao: 'login_erro',
                detalhe: 'Email não existente: $email'
            );
            await Future.delayed(const Duration(milliseconds: 200));
            return null;
        }

        final user = User.fromMap(rows.first);

        // Verificar bloqueio
        if (user.lockedUntil != null && user.lockedUntil! > now) {
            throw Exception('Conta bloqueada. Tente novamente dentro de 30 segundos.');
        }

        // Defensive: if the stored hash is empty or null, treat as invalid credentials
        // and avoid calling BCrypt which will throw on an empty salt/hash.
        bool ok = false;
        try {
          if (user.hash.isNotEmpty) {
            ok = BCrypt.checkpw(senha, user.hash);
          } else {
            // Log an audit event for missing hash to help diagnose DB issues
            await AuditoriaService.registar(
              acao: 'login_erro',
              detalhe: 'Hash de usuário vazio para id=${user.id}',
              userId: user.id,
            );
          }
        } catch (e) {
          // Catch bcrypt errors (e.g., invalid salt length) and treat as auth failure.
          await AuditoriaService.registar(
            acao: 'login_erro',
            detalhe: 'Erro ao verificar senha: ${e.toString()}',
            userId: user.id,
          );
          ok = false;
        }

        if (!ok) {
            final fails = (user.failedAttempts ?? 0) + 1;
            int? lockedUntil;
            
            if (fails >= 5) {
                lockedUntil = DateTime.now()
                    .add(const Duration(seconds: 30))
                    .millisecondsSinceEpoch;
            }

            // Defensive update: only include columns that exist in the table schema.
            final cols = await DatabaseHelper.instance.tableColumns('usuarios');
            final payload = <String, Object?>{};
            if (cols.contains('failed_attempts')) payload['failed_attempts'] = fails;
            if (cols.contains('last_failed_at')) payload['last_failed_at'] = now;
            if (cols.contains('locked_until')) payload['locked_until'] = lockedUntil;

            if (payload.isNotEmpty) {
              await db.update('usuarios', payload, where: 'id = ?', whereArgs: [user.id]);
            }

            await AuditoriaService.registar(
                acao: 'login_erro',
                userId: user.id,
                detalhe: 'Senha incorreta (tentativa $fails)'
            );

            await Future.delayed(const Duration(milliseconds: 200));
            return null;
        }

        // Login bem sucedido - resetar contadores
        final cols2 = await DatabaseHelper.instance.tableColumns('usuarios');
        final resetPayload = <String, Object?>{};
        if (cols2.contains('failed_attempts')) resetPayload['failed_attempts'] = 0;
        if (cols2.contains('last_failed_at')) resetPayload['last_failed_at'] = null;
        if (cols2.contains('locked_until')) resetPayload['locked_until'] = null;

        if (resetPayload.isNotEmpty) {
          await db.update('usuarios', resetPayload, where: 'id = ?', whereArgs: [user.id]);
        }

        await AuditoriaService.registar(
            acao: 'login_sucesso',
            userId: user.id
        );

        return user;
    } catch (e) {
        print('Erro no login: $e');
        throw Exception('Erro durante login: $e');
    }
  }
}
