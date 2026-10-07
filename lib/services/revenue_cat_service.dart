import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();

  static const entitlementId = 'premium';
  static const _androidApiKey = 'goog_lBykTbrKEPHbtPwxSuPQyiuVMPm';
  static const _iosApiKey = 'appl_eygtZWcPgbBMrswltdlksExhFuc';

  static bool _configured = false;
  static String? _linkedUserId;

  static Future<void> initialize() async {
    if (_configured || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final configuration = PurchasesConfiguration(
      Platform.isAndroid ? _androidApiKey : _iosApiKey,
    );
    if (userId != null) configuration.appUserID = userId;

    await Purchases.configure(configuration);
    _configured = true;
    _linkedUserId = userId;
    FirebaseAuth.instance.authStateChanges().listen(_linkFirebaseUser);
  }

  static Future<void> _linkFirebaseUser(User? user) async {
    if (!_configured || user?.uid == _linkedUserId) return;
    try {
      if (user == null) {
        await Purchases.logOut();
        _linkedUserId = null;
      } else {
        await Purchases.logIn(user.uid);
        _linkedUserId = user.uid;
      }
    } catch (error) {
      debugPrint('Unable to update RevenueCat user: $error');
    }
  }

  static bool hasPremium(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(entitlementId);
  }

  static Future<bool> hasPremiumAccess() async {
    if (!_configured) return false;
    return hasPremium(await Purchases.getCustomerInfo());
  }

  static Future<Offering?> getCurrentOffering() async {
    if (!_configured) return null;
    return (await Purchases.getOfferings()).current;
  }

  static Future<CustomerInfo> restorePurchases() {
    return Purchases.restorePurchases();
  }

  static Future<PurchaseResult> purchasePackage(Package package) {
    return Purchases.purchase(PurchaseParams.package(package));
  }

  static Future<Uri?> managementUrl() async {
    if (!_configured) return null;
    final url = (await Purchases.getCustomerInfo()).managementURL;
    return url == null ? null : Uri.tryParse(url);
  }
}
