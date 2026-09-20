import 'prediction_result.dart';

class SocialPost {
  final String id;
  final String username;
  final String userAvatar;
  final String content;
  final PredictionResult prediction;
  final DateTime createdAt;
  int likes;
  bool isLiked;

  SocialPost({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.content,
    required this.prediction,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
  });
}
