import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    required super.companyName,
    required super.companyAddress,
    required super.companyPhone,
    required super.companyEmail,
    required super.currencySymbol,
    required super.dueReminderDays,
    required super.lateFeeAmount,
    required super.invoicePrefix,
    super.updatedAt,
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      companyName: map['companyName'] as String? ?? '',
      companyAddress: map['companyAddress'] as String? ?? '',
      companyPhone: map['companyPhone'] as String? ?? '',
      companyEmail: map['companyEmail'] as String? ?? '',
      currencySymbol: map['currencySymbol'] as String? ?? 'Rs.',
      dueReminderDays: (map['dueReminderDays'] as num?)?.toInt() ?? 5,
      lateFeeAmount: (map['lateFeeAmount'] as num?)?.toDouble() ?? 0,
      invoicePrefix: map['invoicePrefix'] as String? ?? 'NASR-',
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppSettingsModel.fromMap(data);
  }

  /// Creates a model from the domain entity (for passing into data source).
  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) {
    return AppSettingsModel(
      companyName: entity.companyName,
      companyAddress: entity.companyAddress,
      companyPhone: entity.companyPhone,
      companyEmail: entity.companyEmail,
      currencySymbol: entity.currencySymbol,
      dueReminderDays: entity.dueReminderDays,
      lateFeeAmount: entity.lateFeeAmount,
      invoicePrefix: entity.invoicePrefix,
      updatedAt: entity.updatedAt,
    );
  }

  /// Creates a model with all defaults — used when creating the config doc
  /// for the first time.
  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      companyName: '',
      companyAddress: '',
      companyPhone: '',
      companyEmail: '',
      currencySymbol: 'Rs.',
      dueReminderDays: 5,
      lateFeeAmount: 0,
      invoicePrefix: 'NASR-',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'currencySymbol': currencySymbol,
      'dueReminderDays': dueReminderDays,
      'lateFeeAmount': lateFeeAmount,
      'invoicePrefix': invoicePrefix,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppSettingsModel copyWith({
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? currencySymbol,
    int? dueReminderDays,
    double? lateFeeAmount,
    String? invoicePrefix,
    DateTime? updatedAt,
  }) {
    return AppSettingsModel(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      dueReminderDays: dueReminderDays ?? this.dueReminderDays,
      lateFeeAmount: lateFeeAmount ?? this.lateFeeAmount,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
