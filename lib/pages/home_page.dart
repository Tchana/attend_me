import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import 'program_detail_page.dart';
import 'create_program_page.dart';
import 'stats_list_page.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProgramController ctrl = Get.find();
  int _selectedIndex = 0;


  void _onItemTapped(int index) {
    if (index == 2) {

      Get.to(() => CreateProgramPage());
      return;
    }
    setState(() {
      if (index < 2) {
        _selectedIndex = index;
      } else {
        _selectedIndex = index - 1;
      }
    });
  }

  List<Widget> get _pages => [
        DashboardPage(),
        _programsListView(),
        StatsListPage(),
        SettingsPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/attendme.png', height: 32, width: 32),
            const SizedBox(width: 8),
            Text(
              _selectedIndex == 0 ? 'Attend Me' : _selectedIndex == 1 ? 'Programs' : _selectedIndex == 2 ? 'Stats' : 'Settings',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        actionsIconTheme: IconThemeData(color: Colors.black87),
         actions: _selectedIndex == 0 || _selectedIndex == 1
             ? [
                 IconButton(
                   icon: Icon(Icons.search),
                   onPressed: () {
                     showSearch(context: context, delegate: ProgramSearchDelegate(ctrl));
                   },
                 ),
               ]
             : [],
       ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFFF9F9F9),
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Home',
              icon: Icon(Icons.home_filled,
                  color: _selectedIndex == 0 ? Colors.blueAccent : Colors.grey),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              tooltip: 'Programs',
              icon: Icon(Icons.folder,
                  color: _selectedIndex == 1 ? Colors.blueAccent : Colors.grey),
              onPressed: () => _onItemTapped(1),
            ),
            FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: Colors.blueAccent,
              child: Icon(
                Icons.add,
                size: 32,
                color: Color(0xFFF9F9F9),
              ),
              onPressed: () {
                Get.to(() => CreateProgramPage());
              },
            ),
            IconButton(
              tooltip: 'Stats',
              icon: Icon(Icons.bar_chart_outlined,
                  color: _selectedIndex == 2 ? Colors.blueAccent : Colors.grey),
              onPressed: () => _onItemTapped(3),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: Icon(Icons.settings,
                  color: _selectedIndex == 3 ? Colors.blueAccent : Colors.grey),
              onPressed: () => _onItemTapped(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _programsListView() {
    return Obx(() {
      final items = ctrl.programs;
      if (items.isEmpty) {
        return _buildEmptyState();
      }
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final t = items[i];
            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Get.to(() => ProgramDetailPage(programId: t.id));
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showEditProgramDialog(context, t.id, t.title, t.description);
                              } else if (value == 'delete') {
                                _confirmDelete(context, t.id, t.title);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                            icon: Icon(Icons.more_horiz),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.school,
                            '${t.sessions.length} sessions',
                            Colors.blue,
                          ),
                          SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.people,
                            '${t.attendants.length} attendants',
                            Colors.green,
                          ),
                          if (t.googleSheetUrl.isNotEmpty) ...[
                            SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.link,
                              'Linked',
                              Colors.orange,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No programs yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Create your first program to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Get.to(() => CreateProgramPage());
            },
            icon: Icon(Icons.add, color: Color(0xFFFFFFFF)),
            label: Text('Create Program', style: TextStyle(color: Color(0xFFFFFFFF))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF007BFF),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    // color.r/g/b return 0..1 doubles; convert to 0..255 ints
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.fromRGBO(r, g, b, 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Color.fromRGBO(r, g, b, 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String programId, String title) {
    Get.defaultDialog(
      title: 'Delete Program',
      middleText: 'Are you sure you want to delete "$title"?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Color(0xFFF9F9F9),
      buttonColor: Colors.red,
      onConfirm: () async {
        // close confirmation dialog first
        Get.back();
        // show loading
        Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
        try {
          await ctrl.deleteProgram(programId);
          // close loading
          Get.back();
          Get.snackbar('Deleted', 'Program deleted', snackPosition: SnackPosition.BOTTOM);
        } catch (err) {
          // close loading
          Get.back();
          Get.snackbar('Error', 'Failed to delete program: ${err.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
        }
      },
    );
  }

  Future<void> _showEditProgramDialog(BuildContext context, String programId, String currentTitle, String currentDescription) async {
    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(text: currentDescription);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Program'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final newTitle = titleController.text.trim();
                final newDescription = descriptionController.text.trim();
                if (newTitle.isNotEmpty && newDescription.isNotEmpty) {
                  // close edit dialog then show loading spinner while updating
                  Navigator.of(dialogContext).pop();
                  Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
                  try {
                    await ctrl.updateProgram(programId, newTitle, newDescription);
                    Get.back(); // close loading
                    Get.snackbar('Saved', 'Program updated', snackPosition: SnackPosition.BOTTOM);
                  } catch (err) {
                    Get.back(); // close loading
                    Get.snackbar('Error', 'Failed to update program: ${err.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
                  }
                } else {
                  // Show a message if title or description is empty
                  Get.snackbar('Error', 'Title and description cannot be empty',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      colorText: Color(0xFFF9F9F9));
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// SearchDelegate that looks up programs by title and opens ProgramDetailPage
class ProgramSearchDelegate extends SearchDelegate {
  final ProgramController ctrl;

  ProgramSearchDelegate(this.ctrl);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    final matches = ctrl.programs.where((p) => p.title.toLowerCase().contains(q)).toList();
    if (matches.isEmpty) {
      return Center(child: Text('No programs found'));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (_, i) {
        final p = matches[i];
        return ListTile(
          title: Text(p.title),
          subtitle: Text(p.description),
          onTap: () {
            close(context, p);
            Get.to(() => ProgramDetailPage(programId: p.id));
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final suggestions = q.isEmpty ? ctrl.programs : ctrl.programs.where((p) => p.title.toLowerCase().contains(q)).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, i) {
        final p = suggestions[i];
        return ListTile(
          title: Text(p.title),
          onTap: () {
            query = p.title;
            showResults(context);
          },
        );
      },
    );
  }
}
