import 'package:repliq/models/post_model.dart';
import 'package:repliq/models/user_model.dart';

class CommentModel {
  String? id;
  String? reply;
  String? userId;
  String? postId;
  DateTime? createdAt;
  UserModel? user;
  PostModel? post;

  CommentModel({
    this.id,
    this.reply,
    this.userId,
    this.postId,
    this.createdAt,
    this.user,
    this.post,
  });

  CommentModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    reply = json['reply'];
    userId = json['user_id']?.toString();
    postId = json['post_id']?.toString();
    createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    user = json['user'] != null ? UserModel.fromJson(json['user']) : null;
    post = json['post'] != null ? PostModel.fromJson(json['post']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['reply'] = reply;
    data['user_id'] = userId;
    data['post_id'] = postId;
    data['created_at'] = createdAt?.toIso8601String();
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (post != null) {
      data['post'] = post!.toJson();
    }
    return data;
  }
}
