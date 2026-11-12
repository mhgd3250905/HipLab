import 'package:flutter/material.dart';

import '../control/hip_membership.dart';
import 'coach/hip_coach_chat_page.dart';
import 'hip_membership_page.dart';
import 'hip_routes.dart';
import 'library/library_actions.dart';
import 'library/practice_page.dart';

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
  HipMembership membership, {
  LibraryActions? actions,
}) async {
  await Navigator.of(context).push<bool>(
    HipRoute.content<bool>((pageContext) {
      final coachActions = actions?.coach?.configured == true ? actions : null;
      return HipMembershipPage(
        membership: membership,
        onCoach: coachActions == null
            ? null
            : () async {
                if (membership.isPremium) {
                  await openHipCoachChat(pageContext, coachActions);
                }
              },
        onPlan: coachActions == null
            ? null
            : () async {
                if (membership.isPremium) {
                  await openHipCoachChat(
                    pageContext,
                    coachActions,
                    composeOnOpen: true,
                  );
                }
              },
        onWorkout: actions == null
            ? null
            : () async {
                if (membership.isPremium) {
                  await openHipNewGroup(pageContext, actions);
                }
              },
      );
    }),
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
