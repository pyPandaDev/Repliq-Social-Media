import 'package:repliq/models/user_model.dart';

class FollowerModel {
  final int? id;
  final String? userId;
  final String? followingId;
  final DateTime? createdAt;
  final UserModel? follower;    // The user who is following
  final UserModel? following;   // The user being followed

  FollowerModel({
    this.id,
    this.userId,
    this.followingId,
    this.createdAt,
    this.follower,
    this.following,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) {
    return FollowerModel(
      id: json['id'],
      userId: json['user_id'],
      followingId: json['following_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      follower: json['follower'] != null
          ? UserModel.fromJson(json['follower'])
          : null,
      following: json['following'] != null
          ? UserModel.fromJson(json['following'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'following_id': followingId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
} 