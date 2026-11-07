import 'package:equatable/equatable.dart';

class Topic extends Equatable {
  const Topic({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [id, name, description];
}
