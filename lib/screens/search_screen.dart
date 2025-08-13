import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fouta_app/utils/firestore_paths.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _postResults = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _userResults = [];
  bool _loading = false;

  Future<void> _search(String value) async {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _postResults = [];
        _userResults = [];
      });
      return;
    }
    setState(() => _loading = true);
    final firestore = FirebaseFirestore.instance;
    final posts = await firestore
        .collection(FirestorePaths.posts())
        .where('contentLower', isGreaterThanOrEqualTo: query, isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    final users = await firestore
        .collection(FirestorePaths.users())
        .where('displayNameLower', isGreaterThanOrEqualTo: query, isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    if (!mounted) return;
    setState(() {
      _postResults = posts.docs;
      _userResults = users.docs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: const InputDecoration(
                hintText: 'Search posts and users',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              children: [
                const ListTile(title: Text('Posts')),
                if (_postResults.isEmpty)
                  const ListTile(title: Text('No posts found'))
                else
                  ..._postResults.map((d) {
                    final data = d.data();
                    return ListTile(title: Text(data['content'] ?? ''));
                  }),
                const ListTile(title: Text('Users')),
                if (_userResults.isEmpty)
                  const ListTile(title: Text('No users found'))
                else
                  ..._userResults.map((d) {
                    final data = d.data();
                    return ListTile(title: Text(data['displayName'] ?? ''));
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
