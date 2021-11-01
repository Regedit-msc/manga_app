class UserFromGoogle {
  UserFromGoogle(
      {required this.name,
      required this.email,
      required this.profilePicture,
      required this.pro});

  final String name;
  final String email;
  final String profilePicture;
  final String? pro;

  factory UserFromGoogle.fromMap(Map<String, dynamic> json) => UserFromGoogle(
      name: json["name"],
      email: json["email"],
      profilePicture: json["profilePicture"],
      pro: json["pro"]);

  Map<String, dynamic> toMap() => {
        "name": name,
        "email": email,
        "profilePicture": profilePicture,
        "pro": pro
      };
}
