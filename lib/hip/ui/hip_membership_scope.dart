import 'package:flutter/material.dart';

import '../control/hip_membership.dart';
import 'hip_membership_page.dart';
import 'hip_routes.dart';

class HipMembershipScope extends InheritedNotifier<HipMembership> {
  const HipMembershipScope({
    super.key,
    required HipMembership membership,
    required super.child,
  }) : super(notifier: membership);

  static HipMembership? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<HipMembershipScope>()
      ?.notifier;
}

bool hasHipPremium(BuildContext context) =>
    HipMembershipScope.of(context)?.isPremium ?? true;

Future<void> openHipMembership(
  BuildContext context,
  HipMembership membership,
) async {
  await Navigator.of(context).push<bool>(
    HipRoute.content<bool>((_) => HipMembershipPage(membership: membership)),
  );
}

Future<bool> ensureHipPremium(BuildContext context) async {
  final membership = context
      .getInheritedWidgetOfExactType<HipMembershipScope>()
      ?.notifier;
  if (membership == null || membership.isPremium) return true;
  await openHipMembership(context, membership);
  return context.mounted && membership.isPremium;
}
