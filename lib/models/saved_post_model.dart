import 'package:repliq/models/post_model.dart';

class SavedPostModel {
  final String id;
  final String userId;
  final int postId;
  final DateTime createdAt;
  final PostModel? post;

  SavedPostModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
    this.post,
  });

  factory SavedPostModel.fromJson(Map<String, dynamic> json) {
    return SavedPostModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      postId: int.parse(json['post_id'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      post: json['post'] != null ? PostModel.fromJson(json['post']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'created_at': createdAt.toIso8601String(),
      'post': post?.toJson(),
    };
  }
} 