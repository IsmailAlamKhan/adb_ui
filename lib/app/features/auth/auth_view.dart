import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import 'auth_model.dart';
import 'auth_providers.dart';

class AuthView extends HookConsumerWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
    final password = useTextEditingController();
    final isSignUp = useState(false);
    final auth = ref.watch(authControllerProvider);
    final notifier = ref.read(authControllerProvider.notifier);

    ref.listen(authControllerProvider, (prev, next) {
      next.maybeWhen(
        error: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          notifier.clearError();
        },
        orElse: () {},
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isSignUp.value ? 'Create account' : 'Sign in',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(16),
        TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const Gap(12),
        TextField(
          controller: password,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          autofillHints: isSignUp.value
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
        ),
        const Gap(16),
        FilledButton(
          onPressed: auth.maybeWhen(
            loading: () => null,
            orElse: () => () {
              final e = email.text.trim();
              final p = password.text;
              if (e.isEmpty || p.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Enter email and password.')));
                return;
              }
              if (isSignUp.value) {
                notifier.signUp(e, p);
              } else {
                notifier.signIn(e, p);
              }
            },
          ),
          child: auth.maybeWhen(
            loading: () => const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            orElse: () => Text(isSignUp.value ? 'Sign up' : 'Sign in'),
          ),
        ),
        TextButton(
          onPressed: () => isSignUp.value = !isSignUp.value,
          child: Text(
            isSignUp.value ? 'Have an account? Sign in' : 'Need an account? Sign up',
          ),
        ),
        if (!isSignUp.value)
          TextButton(
            onPressed: () async {
              final e = email.text.trim();
              if (e.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Enter your email above first.')));
                return;
              }
              try {
                await notifier.resetPassword(e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Check your email for a reset link.')),
                  );
                }
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
                }
              }
            },
            child: const Text('Forgot password'),
          ),
      ],
    );
  }
}
