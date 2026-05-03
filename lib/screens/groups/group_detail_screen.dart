import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_snackbar.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _groupService = GroupService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return StreamBuilder<List<GroupModel>>(
      stream: _groupService.myGroupsStream(auth.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        GroupModel? group;
        if (snapshot.hasData) {
          final groups = snapshot.data!;
          try {
            group = groups.firstWhere((g) => g.id == widget.groupId);
          } catch (_) {}
        }

        if (group == null && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.sageDark)));
        }
        if (group == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.error_outline, title: 'Group not found', subtitle: 'This group may have been deleted.'));
        }

        final g = group;
        final uid = auth.currentUser?.uid ?? '';
        final isMember = g.memberIds.contains(uid);

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(title: Text(g.name)),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.sageLight, borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.hardEdge,
                    child: g.photoUrl != null
                        ? CachedNetworkImage(imageUrl: g.photoUrl!, fit: BoxFit.cover)
                        : Center(child: Text(g.name[0].toUpperCase(),
                            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.sageDark))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.name, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(g.subject, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.sageMid)),
                  ])),
                ]),
                if (g.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(g.description, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.mutedText)),
                ],
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _InfoChip(label: 'Members', value: '${g.memberCount}'),
                  _InfoChip(label: 'Decks', value: '${g.sharedDeckCount}'),
                  _InfoChip(label: 'Visibility', value: g.isPublic ? 'Public' : 'Private'),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            AppButton(label: 'Open Chat', onPressed: isMember ? () => context.push('/groups/${g.id}/chat') : null),
            const SizedBox(height: 12),
            if (!isMember)
              AppButton(
                label: 'Join Group',
                variant: 'secondary',
                onPressed: () async {
                  final ok = await context.read<GroupProvider>().joinGroup(g.id, uid);
                  if (ok && mounted) showSuccessSnackbar(context, 'Joined ${g.name}!');
                },
              ),
            const SizedBox(height: 20),
            Text('Members', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: g.memberIds.length > 8 ? 9 : g.memberIds.length,
                itemBuilder: (ctx, i) {
                  final members = g.memberIds;
                  if (i == 8) return GestureDetector(
                    onTap: () => _showAllMembers(context, members),
                    child: CircleAvatar(radius: 20, backgroundColor: AppColors.warmGray,
                        child: Text('+${members.length - 8}', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700))),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(radius: 20, backgroundColor: AppColors.sageLight,
                        child: Text(members[i].substring(0, 1).toUpperCase(),
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sageDark))),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('Shared Decks', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _groupService.sharedDecksStream(g.id),
              builder: (ctx, snap) {
                if (!snap.hasData) return const CircularProgressIndicator(color: AppColors.sageDark);
                if (snap.data!.isEmpty) return Text('No shared decks yet.', style: GoogleFonts.dmSans(color: AppColors.mutedText));
                return Column(children: snap.data!.map((d) => ListTile(
                  title: Text(d['name'] ?? '', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('${d['cardCount'] ?? 0} cards'),
                  trailing: TextButton(
                    onPressed: isMember ? () async {
                      await _groupService.addSharedDeckToLibrary(uid, g.id, d['id']);
                      if (mounted) showSuccessSnackbar(context, 'Added to your library!');
                    } : null,
                    child: const Text('Add to library'),
                  ),
                )).toList());
              },
            ),
          ]),
        );
      },
    );
  }

  void _showAllMembers(BuildContext context, List<String> members) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (_, i) => ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.sageLight, child: Text(members[i].substring(0, 1).toUpperCase())),
          title: Text('Member ${i + 1}', style: GoogleFonts.dmSans()),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mutedText)),
    ]);
  }
}
