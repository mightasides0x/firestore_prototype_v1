import 'package:equatable/equatable.dart';

class Topic extends Equatable {
  final String id; // Firestore document ID
  final String name;
  // final String? description; // Add later if needed
  // final String? imageUrl; // Add later if needed

  const Topic({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];

  // Optional: Factory constructor for creating from Firestore data
  factory Topic.fromFirestore(String id, Map<String, dynamic> data) {
    return Topic(
      id: id,
      name: data['name'] as String? ?? 'Unnamed Topic', // Handle potential null
    );
  }
} 