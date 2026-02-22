// In lib/services/data_service.dart

import 'package:event_tracker/utils/date_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/person.dart';
import 'web_file_service.dart';
import 'file_service.dart';

// In lib/services/data_service.dart

class DataService {
  List<Person> _people = [];
  
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  // IMPORTANT: Always return sorted data
  List<Person> get people => DateParser.sortByDate(List.from(_people));
  
  // Load data
  Future<void> loadData() async {
    if (kIsWeb) {
      _people = await WebFileService.loadFromLocal();
      
      if (_people.isEmpty) {
        _people = await WebFileService.loadFromAssets();
        // Sort immediately after loading
        _people = DateParser.sortByDate(_people);
        await WebFileService.saveToLocal(_people);
      } else {
        // Ensure loaded data is sorted
        _people = DateParser.sortByDate(_people);
      }
    } else {
      // Mobile version
      _people = await FileService.loadFromLocal();
      if (_people.isEmpty) {
        _people = await FileService.loadFromAssets();
        _people = DateParser.sortByDate(_people);
        await FileService.saveToLocal(_people);
      } else {
        _people = DateParser.sortByDate(_people);
      }
    }
    
    debugPrint('📊 Loaded ${_people.length} people (sorted)');
  }
  
  // Refresh from assets
  Future<void> refreshFromAssets() async {
    if (kIsWeb) {
      _people = await WebFileService.loadFromAssets();
      _people = DateParser.sortByDate(_people);
      await WebFileService.saveToLocal(_people);
    } else {
      _people = await FileService.loadFromAssets();
      _people = DateParser.sortByDate(_people);
      await FileService.saveToLocal(_people);
    }
  }
  
  // Add person
  Future<void> addPerson(Person person) async {
    _people.add(person);
    _people = DateParser.sortByDate(_people);
    await _saveData();
  }
  
  // Update person
  Future<void> updatePerson(int index, Person updatedPerson) async {
    if (index >= 0 && index < _people.length) {
      _people[index] = updatedPerson;
      _people = DateParser.sortByDate(_people);
      await _saveData();
    }
  }
  
  // Delete person
  Future<void> deletePerson(int index) async {
    if (index >= 0 && index < _people.length) {
      _people.removeAt(index);
      // Still sort even after removal (though not strictly necessary)
      _people = DateParser.sortByDate(_people);
      await _saveData();
    }
  }
  
  // Save data based on platform
  Future<void> _saveData() async {
    if (kIsWeb) {
      await WebFileService.saveToLocal(_people);
    } else {
      await FileService.saveToLocal(_people);
    }
  }
  
  // Get statistics
  Map<String, dynamic> getStatistics() {
    int birthdays = _people.where((p) => p.isBirthday).length;
    int anniversaries = _people.where((p) => p.isAnniversary).length;
    
    Map<int, int> monthCount = {};
    for (var person in _people) {
      monthCount[person.month] = (monthCount[person.month] ?? 0) + 1;
    }
    
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
  
  // Search
  List<Person> searchPeople(String query) {
    if (query.isEmpty) return people; // Uses getter which returns sorted
    
    return people.where((person) {
      return person.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}