import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/circle_provider.dart';
import '../../providers/auth_provider.dart';

class JoinOrCreateCircleScreen extends ConsumerStatefulWidget {
  const JoinOrCreateCircleScreen({super.key});

  @override
  ConsumerState<JoinOrCreateCircleScreen> createState() =>
      _JoinOrCreateCircleScreenState();
}

class _JoinOrCreateCircleScreenState
    extends ConsumerState<JoinOrCreateCircleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Create fields
  final _createFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  // Join fields
  final _joinFormKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createCircle() async {
    if (!_createFormKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final circleService = ref.read(circleServiceProvider);
      final circleId = await circleService.createCircle(
        creatorId: user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Circle created!')),
        );
        context.go('/circles/$circleId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinCircle() async {
    if (!_joinFormKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isJoining = true);
    try {
      final circleService = ref.read(circleServiceProvider);
      final circleId = await circleService.joinCircleByCode(
        userId: user.uid,
        inviteCode: _inviteCodeController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined circle!')),
        );
        context.go('/circles/$circleId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'Join'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Create tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _createFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a Private Circle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a private group and invite friends using a unique code.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Circle Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createCircle,
                      icon: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.group_add),
                      label: Text(_isCreating ? 'Creating...' : 'Create Circle'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Join tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _joinFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join a Circle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Enter the invite code shared by a circle member.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      hintText: 'e.g. ABC123',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter an invite code';
                      }
                      if (v.trim().length < 6) return 'Code must be 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isJoining ? null : _joinCircle,
                      icon: _isJoining
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isJoining ? 'Joining...' : 'Join Circle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
