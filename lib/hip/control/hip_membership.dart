import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/storage/local_state_storage.dart';

enum MembershipTerm {
  monthly,
  annual;

  /// The published Google Play offer length. Eligibility is store-managed.
  int get playAdvertisedTrialDays => switch (this) {
    monthly => 3,
    annual => 7,
  };
}

// U.S. base plan prices recorded in docs/android-membership-2026-11-11.md.
const _defaultPlayOffers = [
  MembershipOffer(
    term: MembershipTerm.annual,
    price: 19.99,
    currency: 'USD',
    localizedPrice: r'US$19.99',
    localizedMonthlyPrice: r'US$1.67',
  ),
  MembershipOffer(
    term: MembershipTerm.monthly,
    price: 2.99,
    currency: 'USD',
    localizedPrice: r'US$2.99',
  ),
];

class MembershipOffer {
  const MembershipOffer({
    required this.term,
    required this.price,
    required this.currency,
    required this.localizedPrice,
    this.localizedMonthlyPrice,
    this.trialDays,
  });

  final MembershipTerm term;
  final double price;
  final String currency;
  final String localizedPrice;
  final String? localizedMonthlyPrice;
  final int? trialDays;

  Map<String, Object?> _priceJson() => {
    'price': price,
    'currency': currency,
    'localizedPrice': localizedPrice,
    'localizedMonthlyPrice': localizedMonthlyPrice,
  };

  static MembershipOffer? _priceFromJson(MembershipTerm term, Object? value) {
    if (value
        case {
          'price': num price,
          'currency': String currency,
          'localizedPrice': String localizedPrice,
          'localizedMonthlyPrice': String? localizedMonthlyPrice,
        }
        when price.isFinite &&
            price > 0 &&
            currency.trim().isNotEmpty &&
            localizedPrice.trim().isNotEmpty) {
      return MembershipOffer(
        term: term,
        price: price.toDouble(),
        currency: currency,
        localizedPrice: localizedPrice,
        localizedMonthlyPrice: localizedMonthlyPrice,
      );
    }
    return null;
  }
}

class MembershipSnapshot {
  const MembershipSnapshot(
    this.appUserId,
    this.expiresAt, {
    this.latestPurchaseAt,
    this.term,
    this.willRenew,
    this.isTrial = false,
  });

  final String appUserId;
  final DateTime? expiresAt;
  final DateTime? latestPurchaseAt;
  final MembershipTerm? term;
  final bool? willRenew;
  final bool isTrial;

  bool isActiveAt(DateTime time) =>
      appUserId.trim().isNotEmpty && (expiresAt?.isAfter(time) ?? false);
}

abstract interface class MembershipStore {
  Future<MembershipSnapshot> refresh();
  Future<List<MembershipOffer>> offers();
  Future<MembershipSnapshot?> purchase(MembershipTerm term);
  Future<MembershipSnapshot> restore();
}

/// Owns the current subscription decision and serializes store transactions.
class HipMembership extends ChangeNotifier {
  HipMembership(
    this._store, {
    DateTime Function()? now,
    this.playOfflineQuotes = false,
    LocalStateStorage? offerStorage,
  }) : _now = now ?? DateTime.now,
       _offerStorage = offerStorage ?? SharedPreferencesLocalStateStorage();

  static const _playPriceCacheKey = 'hip_play_offer_prices_v1';
  final MembershipStore _store;
  final DateTime Function() _now;
  final LocalStateStorage _offerStorage;
  final bool playOfflineQuotes;
  final Map<MembershipTerm, MembershipOffer> _cachedPlayPrices = {};
  Future<void>? _readPlayPrices;
  MembershipSnapshot? _snapshot;
  Future<bool>? _refresh;
  Timer? _expiryTimer;
  int _generation = 0;
  bool _disposed = false;
  bool _busy = false;

  bool get busy => _busy;
  bool get isPremium => !_disposed && (_snapshot?.isActiveAt(_now()) ?? false);
  String? get activeAppUserId => isPremium ? _snapshot?.appUserId : null;
  MembershipSnapshot? get activeSnapshot => isPremium ? _snapshot : null;

  List<MembershipOffer> get defaultPlayOffers =>
      playOfflineQuotes ? _defaultPlayOffers : const [];

  /// Prices that can be shown while the Play connection is unavailable.
  /// These offers carry no trial eligibility or purchase authorization.
  Future<List<MembershipOffer>> offlinePlayOffers() async {
    if (!playOfflineQuotes) return const [];
    await (_readPlayPrices ??= _loadPlayPrices());
    return [
      for (final plan in _defaultPlayOffers)
        _cachedPlayPrices[plan.term] ?? plan,
    ];
  }

  Future<List<MembershipOffer>> offers() async {
    final live = await _store.offers();
    if (playOfflineQuotes && live.isNotEmpty) await _savePlayPrices(live);
    return live;
  }

  Future<void> _loadPlayPrices() async {
    try {
      final raw = await _offerStorage.read(_playPriceCacheKey);
      if (raw == null) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return;
      for (final term in MembershipTerm.values) {
        final price = MembershipOffer._priceFromJson(term, decoded[term.name]);
        if (price != null) _cachedPlayPrices[term] = price;
      }
    } on Object {
      // The built-in reference prices still work if settings cannot be read.
    }
  }

  Future<void> _savePlayPrices(List<MembershipOffer> live) async {
    await (_readPlayPrices ??= _loadPlayPrices());
    try {
      for (final offer in live) {
        final price = MembershipOffer._priceFromJson(
          offer.term,
          offer._priceJson(),
        );
        if (price != null) _cachedPlayPrices[offer.term] = price;
      }
      if (_cachedPlayPrices.isEmpty) return;
      await _offerStorage.write(
        _playPriceCacheKey,
        jsonEncode({
          for (final price in _cachedPlayPrices.values)
            price.term.name: price._priceJson(),
        }),
      );
    } on Object {
      // Storage failures must not interfere with live store quotes or purchases.
    }
  }

  Future<bool> refresh() {
    if (_busy || _disposed) return Future.value(isPremium);
    if (_refresh case final existing?) return existing;
    late final Future<bool> request;
    request = _load().whenComplete(() {
      if (identical(_refresh, request)) _refresh = null;
    });
    return _refresh = request;
  }

  Future<bool> _load() async {
    final generation = _generation;
    try {
      final snapshot = await _store.refresh();
      if (generation == _generation) _publish(snapshot);
    } on Exception {
      if (generation == _generation) _publish(null);
    }
    return isPremium;
  }

  Future<bool> purchase(MembershipTerm term) =>
      _transact(() => _store.purchase(term));

  Future<bool> restore() => _transact(_store.restore);

  Future<bool> _transact(Future<MembershipSnapshot?> Function() action) async {
    if (_busy || _disposed) return false;
    _busy = true;
    _refresh = null;
    final generation = ++_generation;
    notifyListeners();
    try {
      final snapshot = await action();
      if (generation != _generation || snapshot == null) return false;
      _publish(snapshot);
      return isPremium;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// A server denial invalidates the local decision and any in-flight result.
  void rejectPremium() {
    _generation++;
    _refresh = null;
    _publish(null);
  }

  void _publish(MembershipSnapshot? snapshot) {
    if (_disposed) return;
    _snapshot = snapshot;
    _expiryTimer?.cancel();
    final now = _now();
    if (snapshot != null && snapshot.isActiveAt(now)) {
      _expiryTimer = Timer(snapshot.expiresAt!.difference(now), _onExpiry);
    }
    notifyListeners();
  }

  void _onExpiry() {
    if (_disposed) return;
    final remaining = _snapshot?.expiresAt?.difference(_now());
    if (remaining != null && remaining > Duration.zero) {
      _expiryTimer = Timer(remaining, _onExpiry);
      return;
    }
    _publish(null);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _expiryTimer?.cancel();
    super.dispose();
  }
}
