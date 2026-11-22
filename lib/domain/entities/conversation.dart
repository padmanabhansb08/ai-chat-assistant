import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt];
}
