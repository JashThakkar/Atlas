import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../../services/social_service.dart';

class DiscoverFriendsScreen extends ConsumerStatefulWidget {
  const DiscoverFriendsScreen({super.key});

  @override
  ConsumerState<DiscoverFriendsScreen> createState() =>
      _DiscoverFriendsScreenState();
}

class _DiscoverFriendsScreenState
    extends ConsumerState<DiscoverFriendsScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  /// UIDs that already have any relationship with the current user
  /// (pending sent, pending received, or accepted).
  Set<String> _relatedIds = {};
  /// UIDs of users to whom the current user has sent a pending request.
  Set<String> _pendingOutgoing = {};

  @override
  void initState() {
    super.initState();
    _loadExistingRelationships();
  }

  Future<void> _loadExistingRelationships() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;
    final socialService = ref.read(socialServiceProvider);
    final results = await Future.wait([
      socialService.getRelatedUserIds(currentUser.uid),
      socialService.getPendingOutgoingIds(currentUser.uid),
    ]);
    if (mounted) {
      setState(() {
        _relatedIds = results[0];
        _pendingOutgoing = results[1];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final socialService = ref.read(socialServiceProvider);
      final results = await socialService.searchUsers(query.trim());
      final currentUser = ref.read(currentUserProvider).value;
      setState(() {
        _results =
            results.where((u) => u['uid'] != currentUser?.uid).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequest(String toUserId) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;
    setState(() {
      _pendingOutgoing.add(toUserId);
      _relatedIds.add(toUserId);
    });
    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.sendFriendRequest(currentUser.uid, toUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      setState(() {
        _pendingOutgoing.remove(toUserId);
        _relatedIds.remove(toUserId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
              onChanged: (value) => _search(value),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_results.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No users found'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  final uid = user['uid'] as String;
                  final name = user['displayName'] ?? 'Unknown';
                  final bio = user['bio'] as String?;
                  final photoUrl = user['photoUrl'] as String?;
                  final isPending = _pendingOutgoing.contains(uid);
                  final isRelated = _relatedIds.contains(uid);

                  return ListTile(
                    leading: GestureDetector(
                      onTap: () => context.push(
                        '/user/$uid',
                        extra: {'userName': name},
                      ),
                      child: CircleAvatar(
                        backgroundImage: photoUrl != null
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Text(name[0].toUpperCase())
                            : null,
                      ),
                    ),
                    title: Text(name),
                    subtitle: bio != null && bio.isNotEmpty
                        ? Text(
                            bio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: isPending
                        ? const Chip(
                            label: Text('Sent'),
                            avatar: Icon(Icons.check, size: 16),
                          )
                        : isRelated
                            ? const Chip(
                                label: Text('Connected'),
                                avatar: Icon(Icons.people, size: 16),
                              )
                            : ElevatedButton(
                                onPressed: () => _sendRequest(uid),
                                child: const Text('Add'),
                              ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
