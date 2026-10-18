enum MemberStatus {
  active('active'),
  paused('paused'),
  inactive('inactive');

  final String value;
  const MemberStatus(this.value);

  static MemberStatus fromString(String val) {
    return MemberStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => MemberStatus.inactive,
    );
  }
}

enum SubscriptionStatus {
  active('active'),
  expired('expired'),
  paused('paused');

  final String value;
  const SubscriptionStatus(this.value);

  static SubscriptionStatus fromString(String val) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => SubscriptionStatus.expired,
    );
  }
}
