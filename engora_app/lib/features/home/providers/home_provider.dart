import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/learning_profile_model.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  ProfileStats? _stats;
  TodaysPractice? _todaysPractice;
  bool _loading = false;
  String? _error;

  ProfileStats? get stats => _stats;
  TodaysPractice? get todaysPractice => _todaysPractice;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadHome() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.get(ApiConstants.profileStats),
        _api.get(ApiConstants.todaysPractice),
      ]);

      _stats = ProfileStats.fromJson(results[0].data);
      _todaysPractice = TodaysPractice.fromJson(results[1].data);
    } catch (e) {
      _error = 'Failed to load data';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadHome();
}
