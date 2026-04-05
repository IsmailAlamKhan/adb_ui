import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/account_view.dart';
import '../../features/licensing/license_providers.dart';
import '../../utils/utils.dart';
import '../premium/premium_feature.dart';
import '../premium/premium_registry.dart';
import 'gap.dart';

/// Renders [child] only when the user is entitled to this premium feature **and**
/// the closed-source pro package registered a [PremiumFeatureFactory].
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
  });

  final PremiumFeature feature;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(isFeatureUnlockedProvider(feature));
    final proAvailable = PremiumRegistry.isProPackageAvailable;

    if (unlocked && proAvailable) {
      return child;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.black38,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          feature.label,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const Gap(12),
                        Text(
                          proAvailable
                              ? feature.description
                              : 'This feature is included in the Pro build of the app. '
                                  'Use a Pro build and sign in to unlock it.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const Gap(20),
                        if (!proAvailable)
                          Text(
                            'Open-source builds do not ship premium implementations.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        const Gap(12),
                        FilledButton(
                          onPressed: () {
                            NavigatorService.instance
                                .pushWithoutContext((_) => const AccountView());
                          },
                          child: Text(proAvailable ? 'Upgrade' : 'Account & licensing'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
