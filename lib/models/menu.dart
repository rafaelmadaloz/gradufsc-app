class Menu {
  final String? lunch;
  final String? dinner;
  final String common;
  final String dayOfWeek; // nova propriedade adicionada

  Menu({
    this.lunch,
    this.dinner,
    required this.common,
    required this.dayOfWeek,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      lunch: json['lunch'],
      dinner: json['dinner'],
      common: json['common'],
      dayOfWeek: json['dayOfWeek'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lunch': lunch,
      'dinner': dinner,
      'common': common,
      'dayOfWeek': dayOfWeek,
    };
  }
}
