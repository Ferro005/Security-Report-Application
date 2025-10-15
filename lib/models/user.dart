class User {
  final int id;
  final String nome;
  final String email;
  final String hash;              // <- bcrypt hash
  final String tipo;              // admin / usuario
  final int? failedAttempts;      // nº de tentativas falhadas
  final int? lastFailedAt;        // timestamp da última falha
  final int? lockedUntil;         // timestamp até quando está bloqueado

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.hash,
    required this.tipo,
    this.failedAttempts,
    this.lastFailedAt,
    this.lockedUntil,
  });

factory User.fromMap(Map<String, dynamic> m) => User(
      id: m['id'] is int ? m['id'] : int.tryParse(m['id']?.toString() ?? '0') ?? 0,
      nome: m['nome']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
  // Some DB dumps / older schemas use the column name 'senha' instead of 'hash'.
  // Prefer 'hash' but fall back to 'senha' so existing databases don't break.
  hash: m['hash']?.toString() ?? m['senha']?.toString() ?? '',
      tipo: m['tipo']?.toString() ?? '',
      failedAttempts: m['failed_attempts'] is int
          ? m['failed_attempts']
          : int.tryParse(m['failed_attempts']?.toString() ?? ''),
      lastFailedAt: m['last_failed_at'] is int
          ? m['last_failed_at']
          : int.tryParse(m['last_failed_at']?.toString() ?? ''),
      lockedUntil: m['locked_until'] is int
          ? m['locked_until']
          : int.tryParse(m['locked_until']?.toString() ?? ''),
    );


  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'hash': hash,
        'tipo': tipo,
        'failed_attempts': failedAttempts,
        'last_failed_at': lastFailedAt,
        'locked_until': lockedUntil,
      };
}
