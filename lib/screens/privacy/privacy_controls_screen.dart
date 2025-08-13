import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fouta_app/features/safety/muted_words_service.dart';
import 'package:fouta_app/features/safety/safety_service.dart';

class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  static const route = '/privacy';

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  late final String _appId;
  late final String _uid;
  late final SafetyService _safety;
  late final MutedWordsService _mutedWords;

  bool _isPrivate = false;
  String _limitReplies = 'everyone';
  List<String> _mutedWordList = [];
  List<String> _blockedUsers = [];
  List<String> _mutedUsers = [];

  final TextEditingController _newWordController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _muteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appId = Firebase.app().options.projectId ?? 'app';
    _uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    _safety = SafetyService(appId: _appId, userId: _uid);
    _mutedWords = MutedWordsService(appId: _appId, userId: _uid);
    _load();
  }

  Future<void> _load() async {
    final settings = await _safety.fetchSettings();
    final words = await _mutedWords.getMutedWords();
    setState(() {
      _isPrivate = settings['isPrivate'] as bool? ?? false;
      _limitReplies = settings['limitReplies'] as String? ?? 'everyone';
      _blockedUsers = List<String>.from(settings['blockedUserIds'] as List? ?? []);
      _mutedUsers = List<String>.from(settings['mutedUserIds'] as List? ?? []);
      _mutedWordList = words;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Safety & Privacy'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Privacy'),
              Tab(text: 'Safety'),
              Tab(text: 'Muted Words'),
              Tab(text: 'Blocked/Muted'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrivacyTab(),
            _buildSafetyTab(),
            _buildMutedWordsTab(),
            _buildBlockMuteTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Private account'),
          value: _isPrivate,
          onChanged: (v) async {
            await _safety.updatePrivacy(isPrivate: v);
            setState(() => _isPrivate = v);
          },
        ),
      ],
    );
  }

  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: _limitReplies,
          decoration: const InputDecoration(labelText: 'Who can reply?'),
          items: const [
            DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
            DropdownMenuItem(value: 'followers', child: Text('Followers')),
            DropdownMenuItem(value: 'none', child: Text('No one')),
          ],
          onChanged: (v) async {
            if (v == null) return;
            await _safety.updatePrivacy(limitReplies: v);
            setState(() => _limitReplies = v);
          },
        ),
      ],
    );
  }

  Widget _buildMutedWordsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final word in _mutedWordList)
          ListTile(
            title: Text(word),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _mutedWords.removeWord(word);
                setState(() => _mutedWordList.remove(word));
              },
            ),
          ),
        TextField(
          controller: _newWordController,
          decoration: const InputDecoration(labelText: 'Add word'),
        ),
        ElevatedButton(
          onPressed: () async {
            final word = _newWordController.text;
            await _mutedWords.addWord(word);
            _newWordController.clear();
            _mutedWordList = await _mutedWords.getMutedWords();
            setState(() {});
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildBlockMuteTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Blocked Users', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final id in _blockedUsers)
          ListTile(
            title: Text(id),
            trailing: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () async {
                await _safety.unblockUser(id);
                setState(() => _blockedUsers.remove(id));
              },
            ),
          ),
        TextField(
          controller: _blockController,
          decoration: const InputDecoration(labelText: 'Block user ID'),
        ),
        ElevatedButton(
          onPressed: () async {
            final id = _blockController.text.trim();
            if (id.isEmpty) return;
            await _safety.blockUser(id);
            _blockController.clear();
            _blockedUsers = await _safety.getBlockedUserIds();
            setState(() {});
          },
          child: const Text('Block'),
        ),
        const Divider(),
        const Text('Muted Users', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final id in _mutedUsers)
          ListTile(
            title: Text(id),
            trailing: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () async {
                await _safety.unmuteUser(id);
                setState(() => _mutedUsers.remove(id));
              },
            ),
          ),
        TextField(
          controller: _muteController,
          decoration: const InputDecoration(labelText: 'Mute user ID'),
        ),
        ElevatedButton(
          onPressed: () async {
            final id = _muteController.text.trim();
            if (id.isEmpty) return;
            await _safety.muteUser(id);
            _muteController.clear();
            _mutedUsers = await _safety.getMutedUserIds();
            setState(() {});
          },
          child: const Text('Mute'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newWordController.dispose();
    _blockController.dispose();
    _muteController.dispose();
    super.dispose();
  }
}

Map<String, WidgetBuilder> privacyRoutes() {
  return {PrivacyControlsScreen.route: (_) => const PrivacyControlsScreen()};
}
