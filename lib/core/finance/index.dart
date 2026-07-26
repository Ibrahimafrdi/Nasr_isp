// Shared finance value objects — pure Dart. No Flutter, no Firebase, no DI.
//
// These types deliberately know nothing about installations, customers or
// packages: `lib/core/` never imports `lib/features/`. Entities adapt to
// these types, not the other way round.
export 'material_totals.dart';
export 'money_line.dart';
export 'subscriber_margin.dart';
