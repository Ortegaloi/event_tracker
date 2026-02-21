import '/models/person.dart';
import 'file_service.dart';
import 'web_file_service.dart';
import 'package:flutter/foundation.dart';
import '/utils/date_parser.dart';
class DataService {
  List<Person> _people = [];
  
 static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  List<Person> get people => List.unmodifiable(_people);
  
  // Load data (platform-aware)
  Future<void> loadData() async {
    if (kIsWeb) {
      // Web: Load from SharedPreferences
      _people = await WebFileService.loadFromLocal();
      
      // If no local data, load from assets
      if (_people.isEmpty) {
        _people = await WebFileService.loadFromAssets('assets/data/event.txt');
        await WebFileService.saveToLocal(_people);
      }
    } else {
      // Mobile: Use original FileService
      _people = await FileService.loadFromLocal();
      if (_people.isEmpty) {
        _people = await FileService.loadFromAssets();
        await FileService.saveToLocal(_people);
      }
    }
  }
  
  // Refresh from assets (platform-aware)
  Future<void> refreshFromAssets() async {
    if (kIsWeb) {
      _people = await WebFileService.loadFromAssets('assets/data/birthdays.txt');
      await WebFileService.saveToLocal(_people);
    } else {
      _people = await FileService.loadFromAssets();
      await FileService.saveToLocal(_people);
    }
  }
  
  // Add a new person
  Future<void> addPerson(Person person) async {
    _people.add(person);
    _people = DateParser.sortByDate(_people);
    await FileService.saveToLocal(_people);
  }
  
  // Update a person
  Future<void> updatePerson(int index, Person updatedPerson) async {
    if (index >= 0 && index < _people.length) {
      _people[index] = updatedPerson;
      _people = DateParser.sortByDate(_people);
      await FileService.saveToLocal(_people);
    }
  }
  
  // Delete a person
  Future<void> deletePerson(int index) async {
    if (index >= 0 && index < _people.length) {
      _people.removeAt(index);
      await FileService.saveToLocal(_people);
    }
  }
  
  // Search people by name
  List<Person> searchPeople(String query) {
    if (query.isEmpty) return _people;
    
    return _people.where((person) {
      return person.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
  
  // Get statistics
  Map<String, dynamic> getStatistics() {
    int birthdays = _people.where((p) => p.isBirthday).length;
    int anniversaries = _people.where((p) => p.isAnniversary).length;
    
    // Count by month
    Map<int, int> monthCount = {};
    for (var person in _people) {
      monthCount[person.month] = (monthCount[person.month] ?? 0) + 1;
    }
    
    // Find upcoming events
    DateTime now = DateTime.now();
    List<Person> upcomingEvents = _people.where((person) {
      DateTime eventDate = DateTime(now.year, person.month, person.day);
      if (eventDate.isBefore(now)) {
        eventDate = DateTime(now.year + 1, person.month, person.day);
      }
      return eventDate.difference(now).inDays <= 30;
    }).toList();
    
    return {
      'total': _people.length,
      'birthdays': birthdays,
      'anniversaries': anniversaries,
      'monthCount': monthCount,
      'upcomingEvents': upcomingEvents,
    };
  }
}