class AppSettingsEntity {
  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String currencySymbol;
  final int dueReminderDays;
  final double lateFeeAmount;
  final String invoicePrefix;
  final DateTime? updatedAt;

  const AppSettingsEntity({
    this.companyName = '',
    this.companyAddress = '',
    this.companyPhone = '',
    this.companyEmail = '',
    this.currencySymbol = 'Rs.',
    this.dueReminderDays = 5,
    this.lateFeeAmount = 0,
    this.invoicePrefix = 'NASR-',
    this.updatedAt,
  });

  /// Factory that produces a default settings entity for first-time setup.
  factory AppSettingsEntity.defaults() => const AppSettingsEntity();
}
