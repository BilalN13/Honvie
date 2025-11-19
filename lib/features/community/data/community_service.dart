import 'package:flutter/foundation.dart';
import 'package:honvie/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  const CommunityService();

  // ---------------------------------------------------------------------------
  // UPLOAD D'IMAGE POUR LES POSTS
  // ---------------------------------------------------------------------------

  Future<String?> uploadPostImage({
    required Uint8List bytes,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    try {
      const bucket = 'post-images';
      final storagePath = 'posts/$path';

      await supabase.storage.from(bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return supabase.storage.from(bucket).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint("Erreur uploadPostImage : $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // CREER UN POST
  // ---------------------------------------------------------------------------

  Future<bool> createPost({
    required String title,
    required String content,
    required String moodTag,
    bool isAnonymous = false,
    String? authorName,
    String? imageUrl,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase.from('community_posts').insert({
        'user_id': userId,
        'title': title,
        'content': content,
        'mood_tag': moodTag,
        'is_anonymous': isAnonymous,
        'author_name': authorName,
        'image_url': imageUrl,
      });

      return true;
    } catch (e) {
      debugPrint("Erreur createPost : $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // RECUPERER LES POSTS AVEC PAGINATION
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPostsPage({
    required int limit,
    required int offset,
    String? moodFilter,
  }) async {
    try {
      final baseQuery = supabase.from('community_posts').select();

      final filteredQuery = (moodFilter != null && moodFilter.isNotEmpty)
          ? baseQuery.eq('mood_tag', moodFilter)
          : baseQuery;

      final response = await filteredQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erreur getPostsPage : $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPostsPage({
    required String userId,
    required int limit,
    required int offset,
    String? moodFilter,
  }) async {
    try {
      final baseQuery = supabase
          .from('community_posts')
          .select()
          .eq('user_id', userId);

      final filteredQuery = (moodFilter != null && moodFilter.isNotEmpty)
          ? baseQuery.eq('mood_tag', moodFilter)
          : baseQuery;

      final response = await filteredQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erreur getUserPostsPage : $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserLatestPosts({
    int limit = 3,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('community_posts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erreur getUserLatestPosts : $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // LIKE / UNLIKE
  // ---------------------------------------------------------------------------

  Future<bool> hasLikedPost(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint("Erreur hasLikedPost : $e");
      return false;
    }
  }

  Future<bool?> toggleLike(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final existing = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        return true;
      } else {
        await supabase.from('post_likes').delete().eq('id', existing['id']);
        return false;
      }
    } catch (e) {
      debugPrint("Erreur toggleLike : $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // COMMENTAIRES
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCommentsForPost(String postId) async {
    try {
      final res = await supabase
          .from('post_comments')
          .select('id, post_id, author_name, content, created_at, likes_count')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      // ignore: avoid_print
      print('Error getCommentsForPost: $e\n$st');
      return [];
    }
  }

  Future<bool> hasLikedComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await supabase
          .from('comment_likes')
          .select('id')
          .eq('comment_id', commentId)
          .eq('user_id', user.id)
          .maybeSingle();

      return res != null;
    } catch (e, st) {
      // ignore: avoid_print
      print('Error hasLikedComment: $e\n$st');
      return false;
    }
  }

  Future<bool?> toggleCommentLike(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final alreadyLiked = await hasLikedComment(commentId);

      final currentRow = await supabase
          .from('post_comments')
          .select('likes_count')
          .eq('id', commentId)
          .maybeSingle();

      var currentLikes = (currentRow?['likes_count'] ?? 0) as int;

      if (!alreadyLiked) {
        await supabase.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': user.id,
        });
        currentLikes += 1;
      } else {
        await supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', user.id);
        currentLikes = ((currentLikes - 1).clamp(0, 999999)).toInt();
      }

      await supabase
          .from('post_comments')
          .update({'likes_count': currentLikes})
          .eq('id', commentId);

      return !alreadyLiked;
    } catch (e, st) {
      // ignore: avoid_print
      print('Error toggleCommentLike: $e\n$st');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final inserted = await supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
          })
          .select()
          .maybeSingle();

      return inserted != null ? Map<String, dynamic>.from(inserted) : null;
    } catch (e) {
      debugPrint("Erreur addComment : $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    try {
      final updated = await supabase
          .from('post_comments')
          .update({'content': newContent})
          .eq('id', commentId)
          .select()
          .maybeSingle();

      return updated != null ? Map<String, dynamic>.from(updated) : null;
    } catch (e) {
      debugPrint("Erreur updateComment : $e");
      return null;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      await supabase.from('post_comments').delete().eq('id', commentId);
      return true;
    } catch (e) {
      debugPrint("Erreur deleteComment : $e");
      return false;
    }
  }
}
