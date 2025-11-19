import 'package:flutter/material.dart';

import 'package:honvie/features/community/data/community_service.dart';
import 'package:honvie/features/community/presentation/community_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String authorName;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.authorName,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final CommunityService _service = const CommunityService();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;

  List<Map<String, dynamic>> _posts = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isInitialLoading = true;
      _posts = [];
      _offset = 0;
      _hasMore = true;
      _isLoadingMore = false;
    });

    final newPosts = await _service.getUserPostsPage(
      userId: widget.userId,
      limit: _pageSize,
      offset: _offset,
      moodFilter: null,
    );

    if (!mounted) return;
    setState(() {
      _posts = newPosts;
      _isInitialLoading = false;
      _offset = _posts.length;
      _hasMore = newPosts.length == _pageSize;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final newPosts = await _service.getUserPostsPage(
      userId: widget.userId,
      limit: _pageSize,
      offset: _offset,
      moodFilter: null,
    );

    if (!mounted) return;
    setState(() {
      _posts.addAll(newPosts);
      _offset = _posts.length;
      _isLoadingMore = false;
      _hasMore = newPosts.length == _pageSize;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    const threshold = 200.0;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - threshold) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.authorName),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6FE), Color(0xFFF5EEFF)],
          ),
        ),
        child: SafeArea(
          child: _isInitialLoading && _posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadInitialPosts,
                  child: _posts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                "Pas encore de publications.",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 16,
                          ),
                          itemCount: _posts.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              if (_isLoadingMore) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 16.0),
                                  child:
                                      Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (!_hasMore) {
                                return const SizedBox.shrink();
                              }
                              return const SizedBox.shrink();
                            }

                            final post = _posts[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration:
                                  Duration(milliseconds: 300 + index * 40),
                              builder: (context, value, child) {
                                final curved =
                                    Curves.easeOut.transform(value);
                                return Opacity(
                                  opacity: curved,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1 - curved)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildPostCard(post),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return CommunityPageStateCard.buildCard(post);
  }
}

/// Helper class to reuse the post card from CommunityPage.
class CommunityPageStateCard {
  static Widget buildCard(Map<String, dynamic> post) {
    final author = (post['author_name'] as String?) ?? 'Anonyme';
    final title = (post['title'] as String?) ?? '';
    final content = (post['content'] as String?) ?? '';
    final moodTag = (post['mood_tag'] as String?) ?? '';
    final moodEmoji = kMoodEmojis[moodTag] ?? '🙂';
    final createdAt = post['created_at']?.toString();
    final likes = (post['likes_count'] ?? 0) as int;
    final comments = (post['comments_count'] ?? 0) as int;

    Color moodChipColor(String mood) {
      switch (mood.toLowerCase()) {
        case 'joyeux':
          return const Color(0xFFFF9F1C);
        case 'serein':
          return const Color(0xFF2EC4B6);
        case 'triste':
          return const Color(0xFF5E60CE);
        case 'stressé':
        case 'stressǸ':
          return const Color(0xFFFF595E);
        case 'reconnaissant':
          return const Color(0xFF67B26F);
        default:
          return Colors.grey.shade600;
      }
    }

    List<Color> moodGradient(String mood) {
      switch (mood.toLowerCase()) {
        case 'joyeux':
          return [const Color(0xFFFFF1C1), const Color(0xFFFFD6A5)];
        case 'serein':
          return [const Color(0xFFC7F9CC), const Color(0xFFA0E7E5)];
        case 'triste':
          return [const Color(0xFFE0BBFF), const Color(0xFFBDB2FF)];
        case 'stressé':
        case 'stressǸ':
          return [const Color(0xFFFFADAD), const Color(0xFFFF9AA2)];
        case 'reconnaissant':
          return [const Color(0xFFCDEAC0), const Color(0xFFFDFFB6)];
        default:
          return [const Color(0xFFEDE7F6), const Color(0xFFF3E5F5)];
      }
    }

    String formatDate(String? isoString) {
      if (isoString == null) return '';
      try {
        final dt = DateTime.parse(isoString).toLocal();
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return '';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                     gradient: LinearGradient(colors: moodGradient(moodTag)),
                  ),
                  child: Center(
                    child: Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                         formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(content, style: const TextStyle(fontSize: 14, height: 1.35)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (moodTag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: moodChipColor(moodTag).withValues(alpha: 0.12),
                    ),
                    child: Text(
                      moodLabel(moodTag),
                      style: TextStyle(
                        fontSize: 12,
                         color: moodChipColor(moodTag),
                      ),
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          likes.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comments.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
