
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:honvie/features/community/data/community_service.dart';
import 'package:honvie/features/community/presentation/user_profile_page.dart';
import 'package:honvie/features/community/presentation/widgets/honvie_like_button.dart';

const Map<String, String> kMoodEmojis = {
  'Joyeux': '😀',
  'Serein': '😌',
  'Triste': '😢',
  'Stressé': '😣',
  'Reconnaissant': '🙏',
};

String moodLabel(String mood) {
  final emoji = kMoodEmojis[mood];
  return emoji != null ? '$emoji $mood' : mood;
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunityService _service = const CommunityService();
  final ScrollController _scrollController = ScrollController();
  late final RealtimeChannel _postsChannel;
  List<Map<String, dynamic>> _posts = [];
  final Map<String, bool> _likedByUser = {};
  final Map<String, List<Map<String, dynamic>>> _commentsByPost = {};
  final Map<String, bool> _isLoadingComments = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedMood = 'Joyeux';
  final List<String> _feedMoods = const [
    'Tous',
    'Joyeux',
    'Serein',
    'Triste',
    'Stressé',
    'Reconnaissant',
  ];
  String _selectedFeedMood = 'Tous';
  bool _isAnonymous = true;
  bool _isSubmitting = false;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 10;
  int _currentOffset = 0;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;

  String? get _activeMoodFilter =>
      _selectedFeedMood == 'Tous' ? null : _selectedFeedMood;

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: kIsWeb ? null : 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final ext = _extractExtension(picked);
      if (!mounted) return;

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _selectedImageExtension = ext;
      });
    } catch (error, stackTrace) {
      debugPrint('Error picking image: $error\n$stackTrace');
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageExtension = null;
    });
  }

  String _extractExtension(XFile file) {
    final name = file.name;
    final mime = file.mimeType ?? '';
    if (name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      if (ext.isNotEmpty) return ext;
    }
    if (mime.contains('/')) {
      final ext = mime.split('/').last.toLowerCase();
      if (ext.isNotEmpty) return ext;
    }
    return 'jpg';
  }

  Future<void> _openCommentsSheet(Map<String, dynamic> post) async {
    final postId = post['id']?.toString();
    if (postId == null) return;

    setState(() {
      _isLoadingComments[postId] = true;
    });

    try {
      final comments = await _service.getCommentsForPost(postId);
      if (!mounted) return;

      _commentsByPost[postId] = comments;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _CommentsSheet(
            post: post,
            initialComments: comments,
            onAddComment: (newComment) {
              setState(() {
                _commentsByPost.putIfAbsent(postId, () => []);
                _commentsByPost[postId]!.insert(0, newComment);

                final index = _posts.indexWhere((p) => p['id'] == postId);
                if (index != -1) {
                  final current = (_posts[index]['comments_count'] ?? 0) as int;
                  _posts[index]['comments_count'] = current + 1;
                }
              });
            },
            onDeleteComment: (deletedComment) {
              setState(() {
                if (_commentsByPost.containsKey(postId)) {
                  _commentsByPost[postId]!.removeWhere(
                    (c) => c['id'] == deletedComment['id'],
                  );
                }

                final index = _posts.indexWhere((p) => p['id'] == postId);
                if (index != -1) {
                  final current = (_posts[index]['comments_count'] ?? 0) as int;
                  final next = (current - 1).clamp(0, 1 << 31);
                  _posts[index]['comments_count'] = next;
                }
              });
            },
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Error opening comments sheet: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger les commentaires.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingComments[postId] = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _isInitialLoading = true;
    _loadInitialPosts();
    _postsChannel = Supabase.instance.client.channel('public:community_posts');
    _setupRealtime();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _postsChannel.unsubscribe();
    _scrollController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    await _loadInitialPosts();
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isInitialLoading = true;
      _posts = [];
      _currentOffset = 0;
      _hasMore = true;
      _isLoadingMore = false;
    });

    final newPosts = await _service.getPostsPage(
      limit: _pageSize,
      offset: _currentOffset,
      moodFilter: _activeMoodFilter,
    );

    if (!mounted) return;

    setState(() {
      _posts = newPosts;
      _isInitialLoading = false;
      _currentOffset = _posts.length;
      _hasMore = newPosts.length == _pageSize;
    });

    _prefetchLikesForPosts(newPosts);
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final newPosts = await _service.getPostsPage(
      limit: _pageSize,
      offset: _currentOffset,
      moodFilter: _activeMoodFilter,
    );

    if (!mounted) return;

    setState(() {
      _posts.addAll(newPosts);
      _currentOffset = _posts.length;
      _isLoadingMore = false;
      _hasMore = newPosts.length == _pageSize;
    });

    _prefetchLikesForPosts(newPosts);
  }

  void _prefetchLikesForPosts(List<Map<String, dynamic>> posts) {
    for (final post in posts) {
      final id = post['id']?.toString();
      if (id != null && !_likedByUser.containsKey(id)) {
        _service.hasLikedPost(id).then((liked) {
          if (!mounted) return;
          setState(() {
            _likedByUser[id] = liked;
          });
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    const threshold = 200.0;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - threshold) {
      _loadMorePosts();
    }
  }

  void _openUserProfile(String userId, String authorName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          userId: userId,
          authorName: authorName,
        ),
      ),
    );
  }

  void _setupRealtime() {
    _postsChannel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'community_posts',
        callback: _handlePostInserted,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'community_posts',
        callback: _handlePostUpdated,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'community_posts',
        callback: _handlePostDeleted,
      )
      ..subscribe();
  }

  void _handlePostInserted(PostgresChangePayload payload) {
    final newRecord = Map<String, dynamic>.from(payload.newRecord);

    final id = newRecord['id']?.toString();
    if (id == null) return;

    final alreadyExists =
        _posts.any((post) => post['id']?.toString() == id);
    if (alreadyExists) return;

    setState(() {
      _posts.insert(0, Map<String, dynamic>.from(newRecord));
      _currentOffset = _posts.length;
    });
  }

  void _handlePostUpdated(PostgresChangePayload payload) {
    final newRecord = Map<String, dynamic>.from(payload.newRecord);

    final id = newRecord['id']?.toString();
    if (id == null) return;

    final index =
        _posts.indexWhere((post) => post['id']?.toString() == id);
    if (index == -1) return;

    setState(() {
      _posts[index] = Map<String, dynamic>.from(newRecord);
    });
  }

  void _handlePostDeleted(PostgresChangePayload payload) {
    final oldRecord = Map<String, dynamic>.from(payload.oldRecord);

    final id = oldRecord['id']?.toString();
    if (id == null) return;

    final index =
        _posts.indexWhere((post) => post['id']?.toString() == id);
    if (index == -1) return;

    setState(() {
      _posts.removeAt(index);
      _currentOffset = _posts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
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
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildShareButton(),
              const SizedBox(height: 12),
              _buildMoodFilterChips(),
              const SizedBox(height: 12),
              Expanded(
                child: _isInitialLoading && _posts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPostsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.center,
        child: ElevatedButton.icon(
          onPressed: _openShareSheet,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Partager mon histoire'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _feedMoods.map((mood) {
          final isSelected = _selectedFeedMood == mood;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(moodLabel(mood)),
              selected: isSelected,
              onSelected: (_) => _onFeedMoodSelected(mood),
              selectedColor: const Color(0xFFFFE4F2),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.pinkAccent : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onFeedMoodSelected(String mood) {
    if (_selectedFeedMood == mood) return;
    setState(() {
      _selectedFeedMood = mood;
    });
    _loadInitialPosts();
  }

  Widget _buildPostsList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: RefreshIndicator(
          onRefresh: _loadInitialPosts,
          child: _posts.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              "Aucune histoire publiée pour le moment.",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      if (_isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
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
                      duration: Duration(milliseconds: 300 + index * 40),
                      builder: (context, value, child) {
                        final curvedValue = Curves.easeOut.transform(value);
                        return Opacity(
                          opacity: curvedValue,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - curvedValue)),
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
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id']?.toString() ?? '';
    final isLiked = _likedByUser[postId] ?? false;
    final author = (post['author_name'] as String?) ?? 'Anonyme';
    final title = (post['title'] as String?) ?? '';
    final content = (post['content'] as String?) ?? '';
    final moodTag = (post['mood_tag'] as String?) ?? '';
    final moodEmoji = kMoodEmojis[moodTag] ?? '🙂';
    final createdAt = post['created_at']?.toString();
    final likes = (post['likes_count'] ?? 0) as int;
    final comments = (post['comments_count'] ?? 0) as int;
    final authorId = post['user_id']?.toString();
    final imageUrl = (post['image_url'] as String?)?.trim();

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
                GestureDetector(
                  onTap: authorId == null
                      ? null
                      : () => _openUserProfile(authorId, author),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: _moodGradient(moodTag)),
                    ),
                    child: Center(
                      child: Text(
                        moodEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: authorId == null
                            ? null
                            : () => _openUserProfile(authorId, author),
                        child: Text(
                          author,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(createdAt),
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
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
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
                      color: _moodChipColor(moodTag).withValues(alpha: 0.12),
                    ),
                    child: Text(
                      moodLabel(moodTag),
                      style: TextStyle(
                        fontSize: 12,
                        color: _moodChipColor(moodTag),
                      ),
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    HonvieLikeButton(
                      isLiked: isLiked,
                      likeCount: likes,
                      onToggleLike: () {
                        if (postId.isEmpty) return;
                        _onLikeTap(postId);
                      },
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _openCommentsSheet(post),
                      child: Row(
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


  void _openShareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomInset + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Partager mon histoire',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Votre histoire',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Humeur :'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedMood,
                      items: kMoodEmojis.keys
                          .map(
                            (mood) => DropdownMenuItem<String>(
                              value: mood,
                              child: Text(moodLabel(mood)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedMood = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImage,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Ajouter une photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (_selectedImage != null)
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _clearSelectedImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer la photo'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publier en anonyme'),
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Publier'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitPost() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci de remplir le titre et le contenu.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? imageUrl;

    // 1) Si une image est sélectionnée, on tente l’upload
    if (_selectedImageBytes != null && _selectedImageExtension != null) {
      final fileName =
          'post_${DateTime.now().millisecondsSinceEpoch}.$_selectedImageExtension';

      final uploadedUrl = await _service.uploadPostImage(
        bytes: _selectedImageBytes!,
        path: fileName,
        contentType: _selectedImageExtension?.toLowerCase() == 'png'
            ? 'image/png'
            : 'image/jpeg',
      );

      if (uploadedUrl == null) {
        // Upload KO -> on prévient l'utilisateur mais on CONTINUE
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de téléverser la photo. Le post sera publié sans image.',
              ),
            ),
          );
        }
      } else {
        imageUrl = uploadedUrl;
      }
    }

    // 2) Création du post (avec ou sans imageUrl)
    final success = await _service.createPost(
      title: title,
      content: content,
      moodTag: _selectedMood,
      authorName: _isAnonymous ? null : 'Utilisateur Solo',
      imageUrl: imageUrl,
    );

    if (!mounted) return;

    if (success) {
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedImageExtension = null;
        _isAnonymous = true;
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histoire publiée !')),
      );

      await _loadPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la publication.')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }
  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  List<Color> _moodGradient(String mood) {
    switch (mood.toLowerCase()) {
      case 'joyeux':
        return [const Color(0xFFFFF1C1), const Color(0xFFFFD6A5)];
      case 'serein':
        return [const Color(0xFFC7F9CC), const Color(0xFFA0E7E5)];
      case 'triste':
        return [const Color(0xFFE0BBFF), const Color(0xFFBDB2FF)];
      case 'stressé':
        return [const Color(0xFFFFADAD), const Color(0xFFFF9AA2)];
      case 'reconnaissant':
        return [const Color(0xFFCDEAC0), const Color(0xFFFDFFB6)];
      default:
        return [const Color(0xFFEDE7F6), const Color(0xFFF3E5F5)];
    }
  }

  Color _moodChipColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'joyeux':
        return const Color(0xFFFF9F1C);
      case 'serein':
        return const Color(0xFF2EC4B6);
      case 'triste':
        return const Color(0xFF5E60CE);
      case 'stressé':
        return const Color(0xFFFF595E);
      case 'reconnaissant':
        return const Color(0xFF67B26F);
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _onLikeTap(String postId) async {
    final result = await _service.toggleLike(postId);
    if (result == null || !mounted) return;

    setState(() {
      _likedByUser[postId] = result;

      final index = _posts.indexWhere((p) => p['id']?.toString() == postId);
      if (index != -1) {
        final current = (_posts[index]['likes_count'] ?? 0) as int;
        final next = result
            ? current + 1
            : ((current - 1).clamp(0, 999999)).toInt();
        _posts[index]['likes_count'] = next;
      }
    });
  }
}

class _CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final List<Map<String, dynamic>> initialComments;
  final void Function(Map<String, dynamic> newComment) onAddComment;
  final void Function(Map<String, dynamic> deletedComment)? onDeleteComment;

  const _CommentsSheet({
    required this.post,
    required this.initialComments,
    required this.onAddComment,
    this.onDeleteComment,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late List<Map<String, dynamic>> _comments;
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  final CommunityService _communityService = const CommunityService();
  final Map<String, bool> _commentLikedByUser = {};
  final Map<String, int> _commentLikesCount = {};

  @override
  void initState() {
    super.initState();
    _comments = List<Map<String, dynamic>>.from(widget.initialComments);
    _hydrateCommentMeta(_comments);
  }

  Future<void> _hydrateCommentMeta(List<Map<String, dynamic>> comments) async {
    final likedMap = <String, bool>{};
    final countMap = <String, int>{};

    await Future.wait(comments.map((comment) async {
      final id = comment['id']?.toString();
      if (id == null || id.isEmpty) return;
      countMap[id] = (comment['likes_count'] ?? 0) as int;
      likedMap[id] = await _communityService.hasLikedComment(id);
    }));

    if (!mounted) return;
    setState(() {
      _commentLikesCount
        ..clear()
        ..addAll(countMap);
      _commentLikedByUser
        ..clear()
        ..addAll(likedMap);
    });
  }

  Future<void> _submitComment() async {
    final rawText = _commentController.text.trim();
    if (rawText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final postId = widget.post['id']?.toString();
    if (postId == null) {
      if (mounted) {
        setState(() => _isSending = false);
      }
      return;
    }

    try {
      final newComment = await _communityService.addComment(
        postId: postId,
        content: rawText,
      );

      if (!mounted) return;

      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment);
          final newId = newComment['id']?.toString();
          if (newId != null && newId.isNotEmpty) {
            _commentLikedByUser[newId] = false;
            _commentLikesCount[newId] = (newComment['likes_count'] ?? 0) as int;
          }
        });
        widget.onAddComment(newComment);
        _commentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'envoyer le commentaire.")),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Error submitting comment: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'envoyer le commentaire.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _openEditCommentSheet(Map<String, dynamic> comment) async {
    final controller = TextEditingController(
      text: (comment['content'] as String?) ?? '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Modifier le commentaire',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Votre commentaire',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      final newContent = controller.text.trim();
                      if (newContent.isEmpty) return;

                      final commentId = comment['id']?.toString();
                      if (commentId == null || commentId.isEmpty) return;

                      try {
                        final updatedComment = await _communityService
                            .updateComment(
                              commentId: commentId,
                              newContent: newContent,
                            );

                        if (!mounted) return;
                        if (updatedComment == null) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Impossible de modifier le commentaire.",
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          final index = _comments.indexWhere(
                            (c) => c['id'] == updatedComment['id'],
                          );
                          if (index != -1) {
                            _comments[index] = updatedComment;
                          }
                        });

                        if (!mounted) return;
                        navigator.pop();
                      } catch (error, stackTrace) {
                        debugPrint(
                          'Error updating comment: $error\n$stackTrace',
                        );
                      }
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      controller.dispose();
    });
  }

  Future<void> _confirmDeleteComment(Map<String, dynamic> comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Communauté'),
          content: const Text('Cette action est définitive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteComment(comment);
    }
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final supabaseClient = Supabase.instance.client;
    final commentId = comment['id'];
    if (commentId == null) return;

    final postId =
        comment['post_id']?.toString() ?? widget.post['id']?.toString();
    if (postId == null) return;

    try {
      await supabaseClient.from('post_comments').delete().eq('id', commentId);

      final countRow = await supabaseClient
          .from('community_posts')
          .select('comments_count')
          .eq('id', postId)
          .maybeSingle();

      final currentCount = (countRow?['comments_count'] ?? 0) as int;
      final nextCount = ((currentCount - 1).clamp(0, 1 << 31)).toInt();

      await supabaseClient
          .from('community_posts')
          .update({'comments_count': nextCount})
          .eq('id', postId);

      if (!mounted) return;
      setState(() {
        _comments.removeWhere((c) => c['id'] == commentId);
        final idStr = commentId.toString();
        _commentLikedByUser.remove(idStr);
        _commentLikesCount.remove(idStr);
      });

      widget.onDeleteComment?.call(comment);
    } catch (error, stackTrace) {
      debugPrint('Erreur suppression commentaire: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer le commentaire.'),
        ),
      );
    }
  }

  bool _canEdit(Map<String, dynamic> comment) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;
    final commentUserId = comment['user_id'];
    if (commentUserId == null) return false;
    return commentUserId.toString() == currentUserId;
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final author = (comment['author_name'] as String?) ?? 'Anonyme';
    final content = (comment['content'] as String?) ?? '';
    final createdAt = comment['created_at']?.toString();
    final updatedAt = comment['updated_at'];
    final isOwner = _canEdit(comment);
    final commentId = comment['id']?.toString();
    final likesCount = commentId != null
        ? (_commentLikesCount[commentId] ??
            ((comment['likes_count'] ?? 0) as int))
        : (comment['likes_count'] ?? 0) as int;
    final isLiked =
        commentId != null ? (_commentLikedByUser[commentId] ?? false) : false;

    return GestureDetector(
      onLongPress: isOwner ? () => _openEditCommentSheet(comment) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE4F2),
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditCommentSheet(comment);
                            } else if (value == 'delete') {
                              _confirmDeleteComment(comment);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  if (updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Modifié',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isLiked ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTap: commentId == null
                    ? null
                    : () => _onToggleCommentLike(comment),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 18,
                      color: isLiked ? Colors.pinkAccent : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLiked
                            ? Colors.pinkAccent
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggleCommentLike(Map<String, dynamic> comment) async {
    final commentId = comment['id']?.toString();
    if (commentId == null || commentId.isEmpty) return;

    final currentLiked = _commentLikedByUser[commentId] ?? false;
    final currentCount = _commentLikesCount[commentId] ??
        ((comment['likes_count'] ?? 0) as int);

    final nextLiked = !currentLiked;
    final nextCount = nextLiked
        ? currentCount + 1
        : ((currentCount - 1).clamp(0, 999999)).toInt();

    setState(() {
      _commentLikedByUser[commentId] = nextLiked;
      _commentLikesCount[commentId] = nextCount;
      comment['likes_count'] = nextCount;
    });

    final result = await _communityService.toggleCommentLike(commentId);

    if (result == null) {
      if (!mounted) return;
      setState(() {
        _commentLikedByUser[commentId] = currentLiked;
        _commentLikesCount[commentId] = currentCount;
        comment['likes_count'] = currentCount;
      });
    } else if (result != nextLiked && mounted) {
      final correctedCount = result
          ? currentCount + 1
          : ((currentCount - 1).clamp(0, 999999)).toInt();
      setState(() {
        _commentLikedByUser[commentId] = result;
        _commentLikesCount[commentId] = correctedCount;
        comment['likes_count'] = correctedCount;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final postTitle = (widget.post['title'] as String?) ?? '';

    return Padding(
      padding: EdgeInsets.only(top: 40, bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDF7FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    postTitle.isEmpty ? 'Commentaires' : postTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _comments.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun commentaire pour le moment.\nSoyez le premier à partager votre expérience ✨",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(_comments[index]);
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _submitComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      color: Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}










