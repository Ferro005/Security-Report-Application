import '../db/database_helper.dart';
import '../utils/secure_logger.dart';
import '../services/auditoria_service.dart';

/// Service for managing users (admin only)
/// Handles role assignment and user management operations
class UserManagementService {
  
  /// Get all users in the system
  static Future<List<Map<String, dynamic>>> listarTodosUsuarios() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final users = await db.query(
        'usuarios',
        orderBy: 'nome ASC',
      );
      
      SecureLogger.database('Retrieved ${users.length} users');
      return users;
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to list users', e, stackTrace);
      rethrow;
    }
  }

  /// Update a user's role (admin only operation)
  /// 
  /// [adminId] - ID of admin performing the action (for audit trail)
  /// [targetUserId] - ID of user whose role is being changed
  /// [newRole] - New role to assign (must be: 'admin', 'tecnico', or 'user')
  static Future<bool> atualizarRole(
    int adminId,
    int targetUserId,
    String newRole,
  ) async {
    // Validate role
    const allowedRoles = ['admin', 'tecnico', 'user'];
    if (!allowedRoles.contains(newRole)) {
      SecureLogger.warning('Attempted to set invalid role: $newRole');
      throw ArgumentError('Invalid role: $newRole. Must be one of: ${allowedRoles.join(", ")}');
    }

    // Prevent admin from changing their own role
    if (adminId == targetUserId) {
      SecureLogger.warning('Admin $adminId attempted to change their own role');
      throw Exception('Não pode alterar o seu próprio role');
    }

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get current user data for audit trail
      final currentData = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [targetUserId],
      );
      
      if (currentData.isEmpty) {
        throw Exception('Usuário não encontrado');
      }
      
      final oldRole = currentData.first['tipo'] as String;
      final userName = currentData.first['nome'] as String;
      
      // Update role
      final updated = await db.update(
        'usuarios',
        {'tipo': newRole},
        where: 'id = ?',
        whereArgs: [targetUserId],
      );

      if (updated > 0) {
        SecureLogger.info('Role updated for user $targetUserId: $oldRole → $newRole');
        
        // Audit trail
        await AuditoriaService.registar(
          userId: adminId,
          acao: 'ROLE_CHANGE',
          detalhe: 'Alterou role de "$userName" (ID: $targetUserId) de "$oldRole" para "$newRole"',
        );
        
        return true;
      }
      
      return false;
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to update user role', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a user (admin only operation)
  /// 
  /// [adminId] - ID of admin performing the action
  /// [targetUserId] - ID of user to delete
  static Future<bool> deletarUsuario(int adminId, int targetUserId) async {
    // Prevent admin from deleting themselves
    if (adminId == targetUserId) {
      SecureLogger.warning('Admin $adminId attempted to delete themselves');
      throw Exception('Não pode eliminar a sua própria conta');
    }

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get user data for audit trail
      final userData = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [targetUserId],
      );
      
      if (userData.isEmpty) {
        throw Exception('Usuário não encontrado');
      }
      
      final userName = userData.first['nome'] as String;
      final userEmail = userData.first['email'] as String;
      
      // Delete user
      final deleted = await db.delete(
        'usuarios',
        where: 'id = ?',
        whereArgs: [targetUserId],
      );

      if (deleted > 0) {
        SecureLogger.info('User $targetUserId deleted by admin $adminId');
        
        // Audit trail
        await AuditoriaService.registar(
          userId: adminId,
          acao: 'USER_DELETE',
          detalhe: 'Eliminou utilizador "$userName" ($userEmail)',
        );
        
        return true;
      }
      
      return false;
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to delete user', e, stackTrace);
      rethrow;
    }
  }

  /// Get count of users by role
  static Future<Map<String, int>> getStatisticsByRole() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final users = await db.query('usuarios');
      
      final stats = <String, int>{
        'admin': 0,
        'tecnico': 0,
        'user': 0,
      };
      
      for (var user in users) {
        final role = user['tipo'] as String;
        stats[role] = (stats[role] ?? 0) + 1;
      }
      
      return stats;
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to get user statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user has admin privileges
  static Future<bool> isAdmin(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'usuarios',
        columns: ['tipo'],
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return result.isNotEmpty && result.first['tipo'] == 'admin';
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to check admin status', e, stackTrace);
      return false;
    }
  }

  /// Check if user has technician or admin privileges
  static Future<bool> canManageIncidents(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'usuarios',
        columns: ['tipo'],
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (result.isEmpty) return false;
      
      final role = result.first['tipo'] as String;
      return role == 'admin' || role == 'tecnico';
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to check incident management permission', e, stackTrace);
      return false;
    }
  }
}
