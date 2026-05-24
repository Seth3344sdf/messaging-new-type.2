import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/backend.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/pill_button.dart';

/// Magic-link sign-in. Only shown when a real [Backend] is configured and
/// the user is not yet authenticated.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _sent = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _appleSignIn() async {
    final backend = context.read<Backend?>();
    if (backend == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await backend.signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Apple sign-in failed. Configure the Apple provider in '
            'Supabase → Authentication → Providers first.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your work email.');
      return;
    }
    final backend = context.read<Backend?>();
    if (backend == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await backend.signInWithMagicLink(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in',
                    style: serifHeadline(
                      size: 36,
                      color: dark ? AppPalette.inkOnDark : AppPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sent
                        ? 'Check your inbox. The link signs you in on this device.'
                        : "We'll send you a one-tap link. No passwords.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppPalette.inkMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!_sent) ...[
                    _emailField(context),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.downTrend,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PillButton(
                        label: _sending ? 'Sending…' : 'Send magic link',
                        onPressed: _sending ? null : _send,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: dark
                                ? AppPalette.hairlineDark
                                : AppPalette.hairline,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('or',
                              style: theme.textTheme.bodySmall),
                        ),
                        Expanded(
                          child: Divider(
                            color: dark
                                ? AppPalette.hairlineDark
                                : AppPalette.hairline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _appleSignIn,
                        icon: const Icon(Icons.apple, size: 20),
                        label: const Text('Sign in with Apple'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              dark ? AppPalette.inkOnDark : AppPalette.ink,
                          side: BorderSide(
                            color: dark
                                ? AppPalette.hairlineDark
                                : AppPalette.hairline,
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPalette.brandSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppPalette.brand.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_unread_outlined,
                              color: AppPalette.brand, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _email.text.trim(),
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _sent = false),
                            child: const Text('Edit',
                                style: TextStyle(color: AppPalette.brand)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          size: 12, color: AppPalette.presence),
                      const SizedBox(width: 4),
                      Text(
                        'end-to-end encrypted in transit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.presence,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return TextField(
      controller: _email,
      focusNode: _focus,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.go,
      onSubmitted: (_) => _send(),
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'you@work.com',
        filled: true,
        fillColor: dark ? AppPalette.surfaceDark : AppPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.brand, width: 1.5),
        ),
      ),
    );
  }
}
