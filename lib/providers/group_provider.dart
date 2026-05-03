import 'dart:async';
import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<GroupModel> _myGroups = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<GroupModel>>? _subscription;

  List<GroupModel> get myGroups => _myGroups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startListening(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _groupService.myGroupsStream(userId).listen(
      (groups) {
        _myGroups = groups;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Could not load groups. Check your connection.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _myGroups = [];
  }

  Future<GroupModel?> createGroup({
    required String adminId,
    required String name,
    required String description,
    required String subject,
    required bool isPublic,
    String? photoUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final group = await _groupService.createGroup(
        adminId: adminId,
        name: name,
        description: description,
        subject: subject,
        isPublic: isPublic,
        photoUrl: photoUrl,
      );
      return group;
    } catch (e) {
      _errorMessage = 'Could not create group. Check your connection.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroup(String groupId, String userId) async {
    try {
      await _groupService.joinGroup(groupId, userId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not join group. Check your connection.';
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
