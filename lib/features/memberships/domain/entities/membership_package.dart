import 'package:equatable/equatable.dart';

class MembershipPackage extends Equatable {
  final int id;
  final String name;
  final double price;
  final int durationValue;
  final String durationUnit; // 'days' | 'months'
  final bool isActive;
  final bool trackAttendance;
  final bool isPayAsYouGo;
  final DateTime createdAt;

  const MembershipPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.durationValue,
    required this.durationUnit,
    this.isActive = true,
    this.trackAttendance = false,
    this.isPayAsYouGo = false,
    required this.createdAt,
  });

  /// Duration converted to estimated days for sorting/fallback.
  int get estimatedDays => isPayAsYouGo ? 9999 : (durationUnit == 'months' ? durationValue * 30 : durationValue);

  /// Arabic localized duration label (e.g. "30 يوم", "3 شهور", "سنة", "حسب الاستخدام (مفتوح)").
  String get formattedDuration {
    if (isPayAsYouGo) return 'حسب الاستخدام (مفتوح)';
    if (durationUnit == 'months') {
      if (durationValue == 1) return 'شهر واحد';
      if (durationValue == 2) return 'شهران';
      if (durationValue >= 3 && durationValue <= 10) return '$durationValue شهور';
      if (durationValue == 12) return 'سنة';
      return '$durationValue شهر';
    } else {
      if (durationValue == 1) return 'يوم واحد';
      if (durationValue == 2) return 'يومان';
      if (durationValue >= 3 && durationValue <= 10) return '$durationValue أيام';
      return '$durationValue يوم';
    }
  }

  MembershipPackage copyWith({
    int? id,
    String? name,
    double? price,
    int? durationValue,
    String? durationUnit,
    bool? isActive,
    bool? trackAttendance,
    bool? isPayAsYouGo,
    DateTime? createdAt,
  }) {
    return MembershipPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      isActive: isActive ?? this.isActive,
      trackAttendance: trackAttendance ?? this.trackAttendance,
      isPayAsYouGo: isPayAsYouGo ?? this.isPayAsYouGo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        durationValue,
        durationUnit,
        isActive,
        trackAttendance,
        isPayAsYouGo,
        createdAt,
      ];
}
