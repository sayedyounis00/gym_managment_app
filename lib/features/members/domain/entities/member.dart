import 'package:equatable/equatable.dart';

class Member extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String? photoPath;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final bool isSuspended;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    this.photoPath,
    this.age,
    this.weightKg,
    this.heightCm,
    this.isSuspended = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Member copyWith({
    int? id,
    String? name,
    String? phone,
    String? photoPath,
    int? age,
    double? weightKg,
    double? heightCm,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        photoPath,
        age,
        weightKg,
        heightCm,
        isSuspended,
        createdAt,
        updatedAt,
      ];
}
