class Settings {
  final String authCode;

  Settings({required this.authCode});

  Map<String, dynamic> toMap() {
    return {'authCode': authCode};
  }

  static Settings fromMap(Map<String, dynamic> map) {
    return Settings(authCode: map['authCode']);
  }
}
