// ==========================================
// BORSA SİNYAL FLUTTER - NEWS LIST PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:go_router/go_router.dart'

import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/news_item.dart'
import '../../../../shared/widgets.dart'
import '../widgets/news_list_tile.dart'

class NewsListPage extends ConsumerStatefulWidget {
  const NewsListPage({super.key})

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState()
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final _scrollController = ScrollController()

  @override
  void initState() {
    super.initState()
    _scrollController.addListener(_onScroll)
  }

  @override
  void dispose() {
    _scrollController.dispose()
    super.dispose()
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(newsListControllerProvider.notifier).loadMore()
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsListControllerProvider)
    final theme = Theme.of(context)

    return AppScaffold(
      title: 'Tüm Haberler',
      child: RefreshIndicator(
        onRefresh: () => ref.read(newsListControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverList.separated(
              itemCount: state.news.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => Divider(indent: 16, endIndent: 16, height: 1),
              itemBuilder: (_, index) {
                if (index == state.news.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                }
                return NewsListTile(news: state.news[index])
              },
            ),
          ],
        ),
      ),
    )
  }
}

// News List Controller
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:riverpod_annotation/riverpod_annotation.dart'

import '../../../data/providers.dart'
import '../../../data/models/news_item.dart'

part 'news_list_controller.g.dart'

@riverpod
class NewsListController extends _$NewsListController {
  @override
  NewsListState build() {
    return const NewsListState()
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true)
    try {
      final news = await ref.read(latestNewsProvider(50).future)
      state = state.copyWith(isLoading: false, news: news)
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString())
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null)
    ref.invalidate(latestNewsProvider(50))
    await loadInitial()
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return
    state = state.copyWith(isLoadingMore: true)
    try {
      final offset = state.news.length
      final more = await ref.read(latestNewsProvider(20).future)
      // Basitçe daha fazla haber getir (offset desteklenmiyorsa)
      state = state.copyWith(isLoadingMore: false, news: [...state.news, ...more])
    } catch (e) {
      state = state.copyWith(isLoadingMore: false)
    }
  }
}

class NewsListState {
  final bool isLoading
  final bool isLoadingMore
  final String? error
  final List<NewsItem> news

  const NewsListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.news = const [],
  })

  NewsListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<NewsItem>? news,
  }) {
    return NewsListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      news: news ?? this.news,
    )
  }
}