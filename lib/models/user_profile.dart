class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.role = 'user',
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    address: map['address'] as String? ?? '',
    role: map['role'] as String? ?? 'user',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'role': role,
  };
}
