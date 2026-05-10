import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/sermon_cloud_sync.dart';

Future<void> showAccountSheet(
  BuildContext context, {
  required SermonCloudSync cloud,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: _AccountSheetBody(cloud: cloud),
      );
    },
  );
}

class _AccountSheetBody extends StatefulWidget {
  const _AccountSheetBody({required this.cloud});

  final SermonCloudSync cloud;

  @override
  State<_AccountSheetBody> createState() => _AccountSheetBodyState();
}

class _AccountSheetBodyState extends State<_AccountSheetBody> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(bool createAccount) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (createAccount) {
        await widget.cloud.registerWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.cloud.signInWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.cloud.currentUser;
    final theme = Theme.of(context);

    if (user != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Signed in', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(user.email ?? user.uid),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await widget.cloud.signOut();
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: const Text('Sign out'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cloud save', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Sign in to sync your sermon draft to your Firebase account.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(false),
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _submit(true),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
