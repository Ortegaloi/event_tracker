import 'package:flutter/material.dart';
import '../models/person.dart';
import '../services/data_service.dart';
import '/widgets/person_list_tile.dart';
import '/widgets/month_header.dart';
import '/widgets/filter_chips.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService();
  List<Person> _displayedPeople = [];
  bool _showBirthdays = true;
  bool _showAnniversaries = true;
  String _searchQuery = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _dataService.loadData();
    _filterPeople();
    setState(() => _isLoading = false);
  }
  
  void _filterPeople() {
    setState(() {
      _displayedPeople = _dataService.people.where((person) {
        // Filter by type
        if (person.isBirthday && !_showBirthdays) return false;
        if (person.isAnniversary && !_showAnniversaries) return false;
        
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          return person.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        
        return true;
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Birthdays & Anniversaries'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterPeople();
                  },
                ),
              ),
              FilterChips(
                showBirthdays: _showBirthdays,
                showAnniversaries: _showAnniversaries,
                onBirthdaysChanged: (value) {
                  setState(() => _showBirthdays = value);
                  _filterPeople();
                },
                onAnniversariesChanged: (value) {
                  setState(() => _showAnniversaries = value);
                  _filterPeople();
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _displayedPeople.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No events to display',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchQuery = '';
                            _filterPeople();
                          },
                          child: Text('Clear search'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _displayedPeople.length,
                  itemBuilder: (context, index) {
                    final person = _displayedPeople[index];
                    final showMonthHeader = index == 0 || 
                        _displayedPeople[index - 1].month != person.month;
                    
                    return Column(
                      children: [
                        if (showMonthHeader)
                          MonthHeader(
                            month: person.month,
                            count: _displayedPeople
                                .where((p) => p.month == person.month)
                                .length,
                          ),
                        PersonListTile(
                          person: person,
                          onTap: () => _showEditDialog(person, index),
                          onDelete: () => _showDeleteDialog(index),
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddDialog(),
      ),
    );
  }
  
  void _showAddDialog() {
    // Implement add dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Event'),
        content: Text('Add form would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save logic
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showEditDialog(Person person, int index) {
    // Implement edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Event'),
        content: Text('Edit form would go here for ${person.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update logic
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dataService.deletePerson(index);
              _filterPeople();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}