class UserModel {
  final String id;
  final String email; // derived from email/username request
  final String role; // 'admin', 'kader', 'bidan', 'orang_tua'
  final String? namaPanggilan;
  final DateTime? createdAt;
  final String? photoUrl;
  final String?
  photoBase64; // stored directly in Firestore (free alternative to Storage)
  final String? noHp;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.namaPanggilan,
    this.createdAt,
    this.photoUrl,
    this.photoBase64,
    this.noHp,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      role: data['role'] ?? 'orang_tua',
      namaPanggilan: data['namaPanggilan'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : null,
      photoUrl: data['photoUrl'],
      photoBase64: data['photoBase64'],
      noHp: data['noHp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      if (namaPanggilan != null) 'namaPanggilan': namaPanggilan,
      if (createdAt != null) 'createdAt': createdAt,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      if (noHp != null) 'noHp': noHp,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
