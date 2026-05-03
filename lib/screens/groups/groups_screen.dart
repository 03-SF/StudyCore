import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/groups/group_card.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _groupService = GroupService();
  List<GroupModel> _publicGroups = [];
  bool _loadingPublic = false;
  String? _filterSubject;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (_tabController.index == 1) _loadPublic(); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<GroupProvider>().startListening(auth.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPublic() async {
    setState(() => _loadingPublic = true);
    try {
      final groups = await _groupService.getPublicGroups(subject: _filterSubject);
      if (mounted) setState(() => _publicGroups = groups);
    } catch (_) {
      if (mounted) showErrorSnackbar(context, 'Could not load groups.');
    } finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final groupProvider = context.watch<GroupProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Groups')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            decoration: BoxDecoration(color: AppColors.warmGray, borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: AppColors.sageDark, borderRadius: BorderRadius.circular(10)),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.mutedText,
              tabs: const [Tab(text: 'My Groups'), Tab(text: 'Discover')],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              groupProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.sageDark))
                  : groupProvider.myGroups.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: 'No groups yet',
                          subtitle: 'Create or join a study group.',
                          actionLabel: 'Create Group',
                          onAction: () => context.push('/groups/create'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: groupProvider.myGroups.length,
                          itemBuilder: (ctx, i) => GroupCard(
                            group: groupProvider.myGroups[i],
                            onTap: () => context.push('/groups/${groupProvider.myGroups[i].id}'),
                            currentUserId: auth.currentUser?.uid,
                          ),
                        ),
              Column(children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    AppChip(
                      label: 'All',
                      selected: _filterSubject == null,
                      onTap: () { setState(() => _filterSubject = null); _loadPublic(); },
                    ),
                    const SizedBox(width: 8),
                    ...AppConstants.subjects.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: s,
                        selected: _filterSubject == s,
                        onTap: () { setState(() => _filterSubject = s); _loadPublic(); },
                      ),
                    )),
                  ]),
                ),
                Expanded(
                  child: _loadingPublic
                      ? const Center(child: CircularProgressIndicator(color: AppColors.sageDark))
                      : _publicGroups.isEmpty
                          ? const EmptyState(icon: Icons.search_outlined, title: 'No groups found', subtitle: 'Try a different filter.')
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _publicGroups.length,
                              itemBuilder: (ctx, i) {
                                final g = _publicGroups[i];
                                final isMember = auth.currentUser != null && g.memberIds.contains(auth.currentUser!.uid);
                                return GroupCard(
                                  group: g,
                                  onTap: () => context.push('/groups/${g.id}'),
                                  currentUserId: auth.currentUser?.uid,
                                  onJoin: isMember ? null : () async {
                                    if (auth.currentUser == null) return;
                                    final ok = await context.read<GroupProvider>().joinGroup(g.id, auth.currentUser!.uid);
                                    if (ok && mounted) showSuccessSnackbar(context, 'Joined ${g.name}!');
                                  },
                                );
                              },
                            ),
                ),
              ]),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
