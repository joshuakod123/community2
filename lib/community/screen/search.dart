import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:experiment3/community/screen/board_with_search.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // Navigate back on press
          },
          icon: const Icon(Icons.chevron_left),
        ),
        title: const Text(
          'SEARCH',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar using TextField
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search', // Placeholder text
                prefixIcon: const Icon(Icons.search), // Search icon
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(context,MaterialPageRoute(builder: (context) => BoardSearch(search: _searchController.text),));
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200], // Background color
              ),
              onChanged: (value) {
                // Handle search input changes if needed

              },
            ),
            const SizedBox(height: 16.0), // Space between search bar and list
            // Expanded widget to make ListView take the remaining space
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Number of items in the list
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text('Item ${index + 1}'),
                    onTap: () {
                      // Handle item tap if needed
                      // For example, navigate to a detail screen
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
