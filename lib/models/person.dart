// lib/models/person.dart

enum EventType { birthday, anniversary }

class Person {
  final String name;
  final int month;
  final int day;
  final EventType type;
  
  Person({
    required this.name,
    required this.month,
    required this.day,
    required this.type,
  });
  
  bool get isBirthday => type == EventType.birthday;
  bool get isAnniversary => type == EventType.anniversary;
  
  // Get display name (remove emoji for sorting, add for display)
  String get displayName {
    if (isAnniversary) {
      return name.replaceAll('💍 ', ''); // Remove emoji for sorting
    }
    return name;
  }
  
  String get formattedName {
    if (isAnniversary) {
      return '💍 $displayName';
    }
    return '🎂 $name';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'month': month,
      'day': day,
      'type': type.index,
    };
  }
  
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['name'],
      month: json['month'],
      day: json['day'],
      type: EventType.values[json['type']],
    );
  }
  
  @override
  String toString() => '$name: $month/$day (${type.name})';
}