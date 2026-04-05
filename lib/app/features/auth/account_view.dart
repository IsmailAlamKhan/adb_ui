import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../licensing/upgrade_view.dart';
import 'auth_model.dart';
import 'auth_providers.dart';
import 'auth_view.dart';

class AccountView extends ConsumerWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return AdaptiveDialog(
      child: Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: auth.maybeWhen(
          authenticated: (_) => const UpgradeView(),
          orElse: () => ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              AuthView(),
            ],
          ),
        ),
      ),
    );
  }
}
