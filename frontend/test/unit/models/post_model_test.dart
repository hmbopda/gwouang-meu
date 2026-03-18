import 'package:flutter_test/flutter_test.dart';
import 'package:gwangmeu/shared/models/post_model.dart';

import '../../helpers/test_data.dart';

void main() {
  group('PostModel', () {
    test('fromJson post texte', () {
      final post = PostModel.fromJson(postTextJson);

      expect(post.id, 'p-001');
      expect(post.authorId, 'u-001');
      expect(post.villageId, 'v-001');
      expect(post.content, contains('langues africaines'));
      expect(post.moderationStatus, 'APPROVED');
      expect(post.reactionCount, 5);
      expect(post.commentCount, 2);
      expect(post.isLive, false);
      expect(post.isAiSuggestion, false);
    });

    test('fromJson post avec media', () {
      final post = PostModel.fromJson(postMediaJson);

      expect(post.mediaUrl, contains('photo.jpg'));
      expect(post.mediaType, 'IMAGE');
    });

    test('fromJson post live', () {
      final post = PostModel.fromJson(postLiveJson);

      expect(post.isLive, true);
      expect(post.liveViewerCount, 150);
    });

    test('fromJson post suggestion IA', () {
      final post = PostModel.fromJson(postAiJson);

      expect(post.isAiSuggestion, true);
      expect(post.aiConfidence, '0.87');
      expect(post.aiDescription, contains('pere-fils'));
    });

    test('fromJson post multi-media', () {
      final post = PostModel.fromJson(postMultiMediaJson);

      expect(post.mediaUrls, hasLength(3));
    });

    test('toJson puis fromJson preservent les donnees', () {
      final original = PostModel.fromJson(postTextJson);
      final roundTrip = PostModel.fromJson(original.toJson());

      expect(roundTrip, original);
    });

    test('defaults appliques correctement', () {
      final post = PostModel.fromJson({
        'id': 'p-min',
        'authorId': 'u-001',
        'villageId': 'v-001',
        'content': 'Hello',
      });

      expect(post.moderationStatus, 'PENDING');
      expect(post.reactionCount, 0);
      expect(post.commentCount, 0);
      expect(post.shareCount, 0);
      expect(post.flagCount, 0);
      expect(post.reactions, isEmpty);
      expect(post.tags, isEmpty);
      expect(post.mediaUrls, isEmpty);
      expect(post.isLive, false);
      expect(post.isAiSuggestion, false);
      expect(post.isLargeText, false);
    });
  });

  group('PostModelX extension', () {
    test('isApproved vrai si APPROVED', () {
      final post = PostModel.fromJson(postTextJson);
      expect(post.isApproved, true);
    });

    test('isApproved faux si PENDING', () {
      final post = PostModel.fromJson(postPendingJson);
      expect(post.isApproved, false);
    });

    test('isPending vrai si PENDING', () {
      final post = PostModel.fromJson(postPendingJson);
      expect(post.isPending, true);
    });

    test('isPending faux si APPROVED', () {
      final post = PostModel.fromJson(postTextJson);
      expect(post.isPending, false);
    });

    test('postType text pour post simple', () {
      final post = PostModel.fromJson(postTextJson);
      expect(post.postType, PostType.text);
    });

    test('postType media pour post avec mediaUrl', () {
      final post = PostModel.fromJson(postMediaJson);
      expect(post.postType, PostType.media);
    });

    test('postType media pour post avec mediaUrls', () {
      final post = PostModel.fromJson(postMultiMediaJson);
      expect(post.postType, PostType.media);
    });

    test('postType live pour post isLive', () {
      final post = PostModel.fromJson(postLiveJson);
      expect(post.postType, PostType.live);
    });

    test('postType aiSuggestion pour post IA', () {
      final post = PostModel.fromJson(postAiJson);
      expect(post.postType, PostType.aiSuggestion);
    });

    test('hasMediaGrid vrai si plus de 1 mediaUrl', () {
      final post = PostModel.fromJson(postMultiMediaJson);
      expect(post.hasMediaGrid, true);
    });

    test('hasMediaGrid faux si 0 mediaUrls', () {
      final post = PostModel.fromJson(postTextJson);
      expect(post.hasMediaGrid, false);
    });

    test('priorite aiSuggestion > live > media > text', () {
      // Un post qui est a la fois IA et live doit etre IA
      final post = PostModel.fromJson({
        'id': 'p-mix',
        'authorId': 'u-001',
        'villageId': 'v-001',
        'content': 'Mix',
        'isAiSuggestion': true,
        'isLive': true,
        'mediaUrl': 'https://cdn.example.com/x.jpg',
      });
      expect(post.postType, PostType.aiSuggestion);
    });
  });
}
