import 'dart:async';

import 'package:flutter/foundation.dart';

enum MembershipTerm { monthly, annual }

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
}

class MembershipSnapshot {
  const MembershipSnapshot(
    this.appUserId,
    this.expiresAt, {
    this.term,
    this.willRenew,
    this.isTrial = false,
  });

  final String appUserId;
  final DateTime? expiresAt;
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
  HipMembership(this._store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MembershipStore _store;
  final DateTime Function() _now;
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

  Future<List<MembershipOffer>> offers() => _store.offers();

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
