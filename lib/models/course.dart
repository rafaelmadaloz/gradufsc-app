import 'dart:convert';

class Course {
  String name;
  List<String> professors;
  String classCode;
  String code;
  String semester;

  Course(this.name, this.professors, this.classCode, this.code, this.semester);

  Map<String, dynamic> toMap() {
    return {
      'id': "$code|$classCode|$semester",
      'name': name,
      'professors': professors.map((string) => string).toList(),
      'class': classCode,
      'code': code,
      'semester': semester,
    };
  }

  static Course fromJson(Map<String, dynamic> json) {
    return Course(
      json['name'],
      List<String>.from(jsonDecode(json['professors'])),
      json['class'],
      json['code'],
      json['semester'],
    );
  }
}
