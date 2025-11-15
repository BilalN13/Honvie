import 'package:honvie/core/supabase_client.dart';

class CommunityService {
  const CommunityService();

  Future<List<Map<String, dynamic>>> getLatestPosts() async {
    try {
      final response = await supabase
          .from('community_posts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);

      final data = response as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error fetching community posts: $error\n$stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPostsPage({
    required int limit,
    required int offset,
  }) async {
    try {
      final response = await supabase
          .from('community_posts')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final data = response as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error fetching paginated community posts: $error\n$stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPosts({
    int limit = 20,
    int offset = 0,
    String? moodTag,
    String? userId,
  }) async {
    try {
      dynamic query = supabase
          .from('community_posts')
          .select('*')
          .order('created_at', ascending: false);

      if (moodTag != null && moodTag.isNotEmpty) {
        query = query.eq('mood_tag', moodTag);
      }
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      final response = await query.range(offset, offset + limit - 1);
      final data = response as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error fetching filtered posts: $error\n$stackTrace');
      return [];
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    required String moodTag,
    String? authorName,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await supabase.from('community_posts').insert({
        'user_id': user.id,
        'author_name': authorName ?? 'Anonyme',
        'title': title,
        'content': content,
        'mood_tag': moodTag,
      });

      return true;
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error creating community post: $error\n$stackTrace');
      return false;
    }
  }

  Future<bool> hasLikedPost(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await supabase
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      return res != null;
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error checking like: $error\n$stackTrace');
      return false;
    }
  }

  /// Retourne true si après l’appel le post est LIKÉ, false s’il est UNLIKÉ.
  Future<bool?> toggleLike(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final liked = await hasLikedPost(postId);

      final currentRow = await supabase
          .from('community_posts')
          .select('likes_count')
          .eq('id', postId)
          .maybeSingle();

      int currentLikes = (currentRow?['likes_count'] ?? 0) as int;

      if (!liked) {
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
        currentLikes += 1;
      } else {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
        currentLikes = (currentLikes - 1).clamp(0, 999999);
      }

      await supabase
          .from('community_posts')
          .update({'likes_count': currentLikes})
          .eq('id', postId);

      return !liked;
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error toggling like: $error\n$stackTrace');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCommentsForPost(String postId) async {
    try {
      final res = await supabase
          .from('post_comments')
          .select('id, post_id, author_name, content, created_at, user_id')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error loading comments: $error\n$stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addComment({
    required String postId,
    required String content,
    String? authorName,
  }) async {
    final user = supabase.auth.currentUser;
    if (content.trim().isEmpty) return null;

    try {
      final insertPayload = {
        'post_id': postId,
        'content': content.trim(),
        'author_name': authorName ?? 'Anonyme',
        'user_id': user?.id,
      };

      final inserted = await supabase
          .from('post_comments')
          .insert(insertPayload)
          .select()
          .single();

      final current = await supabase
          .from('community_posts')
          .select('comments_count')
          .eq('id', postId)
          .maybeSingle();

      int currentCount = (current?['comments_count'] ?? 0) as int;
      currentCount++;

      await supabase
          .from('community_posts')
          .update({'comments_count': currentCount})
          .eq('id', postId);

      return Map<String, dynamic>.from(inserted);
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error adding comment: $error\n$stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    try {
      final updated = await supabase
          .from('post_comments')
          .update({'content': newContent})
          .eq('id', commentId)
          .select()
          .single();

      return Map<String, dynamic>.from(updated);
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('Error updating comment: $error\n$stackTrace');
      rethrow;
    }
  }
}
