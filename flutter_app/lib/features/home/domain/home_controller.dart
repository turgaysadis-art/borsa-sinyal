// ==========================================
// BORSA SİNYAL FLUTTER - HOME CONTROLLER
// ==========================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';
import '../../../data/models/signal.dart';
import '../../../data/models/news_item.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  HomeState build() {
    return const HomeState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Paralel yükleme
      final results = await Future.wait([
        ref.read(latestSignalProvider.future),
        ref.read(signalsProvider(SignalsQuery(limit: 20)).future),
        ref.read(latestNewsProvider(20).future),
      ]);
      
      state = state.copyWith(
        isLoading: false,
        todaySignal: results[0],
        history: results[1],
        latestNews: results[2],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Cache'i invalidate et
      ref.invalidate(latestSignalProvider);
      ref.invalidate(signalsProvider(SignalsQuery(limit: 20)));
      ref.invalidate(latestNewsProvider(20));
      ref.invalidate(marketSummaryProvider);
      ref.invalidate(technicalSnapshotsProvider);
      
      // Yeniden yükle
      await loadInitial();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreHistory() async {
    if (state.isLoadingHistory) return;
    
    state = state.copyWith(isLoadingHistory: true);
    
    try {
      final offset = state.history.length;
      final more = await ref.read(signalsProvider(SignalsQuery(limit: 20, offset: offset)).future);
      
      state = state.copyWith(
        isLoadingHistory: false,
        history: [...state.history, ...more],
      );
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }
}

class HomeState {
  final bool isLoading;
  final bool isLoadingHistory;
  final String? error;
  final Signal? todaySignal;
  final List<Signal> history;
  final List<NewsItem> latestNews;

  const HomeState({
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.error,
    this.todaySignal,
    this.history = const [],
    this.latestNews = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    bool? isLoadingHistory,
    String? error,
    Signal? todaySignal,
    List<Signal>? history,
    List<NewsItem>? latestNews,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error ?? this.error,
      todaySignal: todaySignal ?? this.todaySignal,
      history: history ?? this.history,
      latestNews: latestNews ?? this.latestNews,
    );
  }
}