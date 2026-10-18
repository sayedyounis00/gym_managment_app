enum Gender {
  male,
  female;

  String get label {
    switch (this) {
      case Gender.male:
        return 'ذكر';
      case Gender.female:
        return 'أنثى';
    }
  }
}
