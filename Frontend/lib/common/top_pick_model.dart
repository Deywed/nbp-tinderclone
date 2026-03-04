import 'package:tinderclone/common/user_model.dart';

class TopPickModel {
  final UserModel user;
  final int likeCount;

  const TopPickModel({required this.user, required this.likeCount});

  factory TopPickModel.fromJson(Map<String, dynamic> json) {
    return TopPickModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }
}
