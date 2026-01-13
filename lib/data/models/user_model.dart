class UserModel {
  final String token;
  final String userId;
  final String fullName;
  final bool status;
  final int userType;

  UserModel({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.status,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserModel(
      token: data['token'] as String,
      userId: data['userId'] as String,
      fullName: data['fullName'] as String,
      status: data['status'] as bool,
      userType: data['userType'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'fullName': fullName,
      'status': status,
      'userType': userType,
    };
  }
}
