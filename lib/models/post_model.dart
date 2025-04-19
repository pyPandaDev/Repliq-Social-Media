import 'package:repliq/models/like_model.dart';
import 'package:repliq/models/user_model.dart';

class PostModel {
  String? id;
  String? content;
  String? image;
  String? createdAt;
  int? commentCount;
  int? likeCount;
  String? userId;
  UserModel? user;
  List<LikeModel>? likes;

  PostModel(
      {
        this.id,
        this.content,
        this.image,
        this.createdAt,
        this.commentCount,
        this.likeCount,
        this.userId,
        this.user
      });

  PostModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    content = json['content'];
    image = json['image'];
    createdAt = json['created_at'];
    commentCount = json['comment_count'];
    likeCount = json['like_count'];
    userId = json['user_id'];
    user = json['user'] != null ?  UserModel.fromJson(json['user']) : null;
    if (json['likes'] != null) {
      likes = <LikeModel>[];
      json['likes'].forEach((v) {
        likes!.add(LikeModel.fromJson(v));
      });
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['id'] = id;
    data['content'] = content;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['comment_count'] = commentCount;
    data['like_count'] = likeCount;
    data['user_id'] = userId;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}



