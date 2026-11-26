import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Thin wrapper around the Play Store in-app review sheet. Never throws:
/// a failed or unavailable review (for example a sideloaded build that is
/// not on the Play Store) simply does nothing.
class RateService {
  RateService._();

  static Future<void> requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (e) {
      debugPrint('QUBA: review request failed: $e');
    }
  }
}
