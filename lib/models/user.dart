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
        id: m['id'] as int,
        nome: m['nome'] as String,
        email: m['email'] as String,
        hash: m['hash'] as String,              // agora mapeia a coluna nova
        tipo: m['tipo'] as String,
        failedAttempts: m['failed_attempts'] as int?,
        lastFailedAt: m['last_failed_at'] as int?,
        lockedUntil: m['locked_until'] as int?,
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
