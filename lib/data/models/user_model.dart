class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? referralCode;
  final bool isMember;
  final String? membershipPlanId;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.referralCode,
    this.isMember = false,
    this.membershipPlanId,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? referralCode,
    bool? isMember,
    String? membershipPlanId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      referralCode: referralCode ?? this.referralCode,
      isMember: isMember ?? this.isMember,
      membershipPlanId: membershipPlanId ?? this.membershipPlanId,
    );
  }
}
