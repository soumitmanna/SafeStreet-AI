import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

sealed class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileModel profile;
  ProfileLoaded(this.profile);
}

class ProfileEmpty extends ProfileState {}

class ProfileError extends ProfileState {
  final ProfileException error;
  final String userMessage;
  ProfileError(this.error, this.userMessage);
}

class ProfileRetrying extends ProfileState {}

class ProfileController extends ChangeNotifier {
  final ProfileService _service;
  
  ProfileState _state = ProfileLoading();
  ProfileState get state => _state;

  DateTime? _lastFetchTime;
  UserProfileModel? _lastProfile;

  static const Duration _kProfileCacheTtl = Duration(minutes: 5);

  ProfileController({ProfileService? service}) : _service = service ?? ProfileService();

  Future<void> loadProfile({bool forceServerFetch = false}) async {
    if (_lastFetchTime != null && !forceServerFetch) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _kProfileCacheTtl && _lastProfile != null) {
        debugPrint('[ProfileController] Cache hit — returning in-memory profile (age: ${elapsed.inSeconds}s)');
        _state = ProfileLoaded(_lastProfile!);
        notifyListeners();
        return;
      }
    }

    if (forceServerFetch) {
      _lastFetchTime = null;
    } else {
      debugPrint('[ProfileController] Cache miss — fetching from Firestore');
    }

    _state = ProfileLoading();
    notifyListeners();

    try {
      final profile = await _service.loadProfile(forceServerFetch: forceServerFetch);
      _lastProfile = profile;
      _lastFetchTime = DateTime.now();

      if (profile.uid.isEmpty || (profile.displayName.isEmpty && profile.email.isEmpty)) {
        _state = ProfileEmpty();
      } else {
        debugPrint('[ProfileController] Profile loaded — displayName: ${profile.displayName}, badges: ${profile.badges.length}');
        _state = ProfileLoaded(profile);
      }
    } on ProfileException catch (e) {
      debugPrint('[ProfileController] Error state: ${e.runtimeType} — ${e.message}');
      _state = ProfileError(e, e.message);
    } catch (e) {
      debugPrint('[ProfileController] Error state: ${e.runtimeType} — $e');
      const error = ProfileDataCorruptedException();
      _state = ProfileError(error, error.message);
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    debugPrint('[ProfileController] Pull-to-refresh started');
    await loadProfile(forceServerFetch: true);
    if (_state is ProfileLoaded || _state is ProfileEmpty) {
      debugPrint('[ProfileController] Pull-to-refresh completed');
    }
  }

  Future<void> retry() async {
    debugPrint('[ProfileController] Retry initiated');
    _state = ProfileRetrying();
    notifyListeners();
    // Brief delay to allow UI to show retrying state
    await Future.delayed(const Duration(milliseconds: 300));
    await loadProfile(forceServerFetch: true);
  }

  void invalidateCache() {
    _lastFetchTime = null;
    _lastProfile = null;
  }
}
