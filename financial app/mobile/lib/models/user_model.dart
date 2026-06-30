class User {
  final String id;
  final String fullName;
  final double monthlyIncome;
  final String? persona;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.monthlyIncome,
    this.persona,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? 'User',
      monthlyIncome: (map['monthly_income'] ?? 0).toDouble(),
      persona: map['persona'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'monthly_income': monthlyIncome,
      'persona': persona,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
