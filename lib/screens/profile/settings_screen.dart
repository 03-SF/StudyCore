import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_notifier.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _dailyGoal = AppConstants.defaultDailyGoal;
  bool _reminderEnabled = false;
  bool _groupMessages = true;
  bool _aiHints = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String _quizMode = 'Multiple Choice';
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyGoal = prefs.getInt(AppConstants.prefKeyDailyGoal) ?? AppConstants.defaultDailyGoal;
      _reminderEnabled = prefs.getBool(AppConstants.prefKeyReminderEnabled) ?? false;
      _groupMessages = prefs.getBool(AppConstants.prefKeyGroupMessages) ?? true;
      _aiHints = prefs.getBool(AppConstants.prefKeyAiHints) ?? true;
      _quizMode = prefs.getString(AppConstants.prefKeyQuizMode) ?? 'Multiple Choice';
      final hour = prefs.getInt('reminder_hour') ?? 9;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _showChangePassword() async {
    final auth = context.read<AuthProvider>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Password',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!, style: GoogleFonts.dmSans(color: AppColors.danger, fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageDark),
                  onPressed: () async {
                    if (newCtrl.text != confirmCtrl.text) {
                      setM(() => error = 'Passwords do not match.');
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      setM(() => error = 'Password must be at least 6 characters.');
                      return;
                    }
                    try {
                      // Re-authenticate first
                      final email = auth.currentUser?.email ?? '';
                      await auth.signIn(email: email, password: currentCtrl.text);
                      await auth.changePassword(newCtrl.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Password changed successfully'),
                            backgroundColor: AppColors.sageDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      setM(() => error = 'Current password is incorrect.');
                    }
                  },
                  child: const Text('Update Password', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sageMid, letterSpacing: 0.8)),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(children: [
            e.value,
            if (!isLast) const Divider(height: 1, indent: 16),
          ]);
        }).toList()),
      ),
      const SizedBox(height: 20),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _section('LEARNING', [
          ListTile(
            title: const Text('Daily Goal'),
            subtitle: Text('$_dailyGoal cards per day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (ctx) => StatefulBuilder(
                builder: (ctx, setM) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Daily Goal: $_dailyGoal cards', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
                    Slider(value: _dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, activeColor: AppColors.sageDark,
                        onChanged: (v) { setM(() => _dailyGoal = v.round()); setState(() => _dailyGoal = v.round()); }),
                    ElevatedButton(onPressed: () async {
                      await _savePref(AppConstants.prefKeyDailyGoal, _dailyGoal);
                      if (mounted) Navigator.pop(ctx);
                    }, child: const Text('Save')),
                  ]),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Quiz Mode'),
            subtitle: Text(_quizMode),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: ['Multiple Choice', 'True/False'].map((m) => ListTile(
                title: Text(m),
                leading: Radio<String>(value: m, groupValue: _quizMode, activeColor: AppColors.sageDark, onChanged: (_) async {
                  setState(() => _quizMode = m);
                  await _savePref(AppConstants.prefKeyQuizMode, m);
                  if (mounted) Navigator.pop(ctx);
                }),
              )).toList()),
            ),
          ),
          SwitchListTile(
            value: _aiHints,
            onChanged: (v) async { setState(() => _aiHints = v); await _savePref(AppConstants.prefKeyAiHints, v); },
            activeColor: AppColors.sageDark,
            title: const Text('AI Hints'),
            subtitle: const Text('Show AI suggestions in card editor'),
          ),
        ]),
        _section('NOTIFICATIONS', [
          SwitchListTile(
            value: _reminderEnabled,
            onChanged: (v) async {
              setState(() => _reminderEnabled = v);
              await _savePref(AppConstants.prefKeyReminderEnabled, v);
              if (v) {
                await _notificationService.requestPermission();
                await _notificationService.scheduleDailyReminder(_reminderTime.hour, _reminderTime.minute);
              } else {
                await _notificationService.cancelAllNotifications();
              }
            },
            activeColor: AppColors.sageDark,
            title: const Text('Daily Reminders'),
          ),
          if (_reminderEnabled) ListTile(
            title: const Text('Reminder Time'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _reminderTime);
              if (picked != null) {
                setState(() => _reminderTime = picked);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('reminder_hour', picked.hour);
                await prefs.setInt('reminder_minute', picked.minute);
                await _notificationService.scheduleDailyReminder(picked.hour, picked.minute);
              }
            },
          ),
          SwitchListTile(
            value: _groupMessages,
            onChanged: (v) async { setState(() => _groupMessages = v); await _savePref(AppConstants.prefKeyGroupMessages, v); },
            activeColor: AppColors.sageDark,
            title: const Text('Group Message Notifications'),
          ),
        ]),
        _section('APPEARANCE', [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Text('Theme', style: GoogleFonts.dmSans(fontSize: 15)),
            const Spacer(),
            ...['Light', 'Dark', 'System'].map((m) {
              final mode = m == 'Light' ? ThemeMode.light : m == 'Dark' ? ThemeMode.dark : ThemeMode.system;
              final selected = themeNotifier.themeMode == mode;
              return Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(
                label: Text(m),
                selected: selected,
                selectedColor: AppColors.sageLight,
                onSelected: (_) => themeNotifier.setMode(mode),
              ));
            }),
          ])),
        ]),
        _section('ACCOUNT', [
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePassword(),
          ),
          ListTile(
            title: Text('Delete Account', style: GoogleFonts.dmSans(color: AppColors.danger)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.danger),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (d) {
                  final ctrl = TextEditingController();
                  return AlertDialog(
                    title: const Text('Delete Account'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Type DELETE to confirm.'),
                      const SizedBox(height: 12),
                      TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'DELETE')),
                    ]),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(d, ctrl.text == 'DELETE'),
                        child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true && mounted) {
                try {
                  await auth.deleteAccount();
                  if (mounted) context.go('/splash');
                } catch (_) {}
              }
            },
          ),
        ]),
      ]),
    );
  }
}
