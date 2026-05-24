import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/avatar_library.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import '../widgets/pill_button.dart';

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key});

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  late final TextEditingController _initialsCtrl;
  late PaperTone _tone;
  String? _myAvatarIdSnapshot;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final current = app.specFor(app.me.avatarId);
    _myAvatarIdSnapshot = app.me.avatarId;
    _initialsCtrl =
        TextEditingController(text: current?.initials ?? 'YO');
    _tone = current?.tone ?? PaperTone.paper;
  }

  @override
  void dispose() {
    _initialsCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final v = _initialsCtrl.text.trim();
    if (v.isEmpty) return '··';
    return v.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final previewSpec = AvatarLibrary.custom(
      id: _myAvatarIdSnapshot ?? 'preview',
      initials: _initials,
      tone: _tone,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Edit avatar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(child: AvatarSpecView(spec: previewSpec, size: 112)),
          const SizedBox(height: 24),
          _label(context, 'initials'),
          const SizedBox(height: 8),
          TextField(
            controller: _initialsCtrl,
            onChanged: (_) => setState(() {}),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'YO',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                color: AppPalette.inkLight,
              ),
              filled: true,
              fillColor: dark ? AppPalette.surfaceDark : AppPalette.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.ink),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label(context, 'tone'),
          const SizedBox(height: 10),
          Row(
            children: PaperTone.values.map((t) {
              final swatch = AvatarLibrary.custom(
                id: 'tone_$t',
                initials: _initials,
                tone: t,
              );
              final selected = t == _tone;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _tone = t),
                  child: AvatarSpecView(
                    spec: swatch,
                    size: 56,
                    selected: selected,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _uploadPhoto,
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: const Text('Upload a photo instead'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.brand,
              side: const BorderSide(color: AppPalette.brand),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'cancel',
                  style: TextStyle(color: AppPalette.inkMuted),
                ),
              ),
              const Spacer(),
              PillButton(
                label: 'Save',
                onPressed: () {
                  context
                      .read<AppState>()
                      .updateMyAvatar(initials: _initials, tone: _tone);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    final backend = context.read<Backend?>();
    if (backend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo upload needs the live backend.'),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;
    try {
      final bytes = await picked.readAsBytes();
      await backend.uploadAvatar(bytes, filename: picked.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Widget _label(BuildContext context, String t) {
    final theme = Theme.of(context);
    return Text(
      t,
      style: theme.textTheme.labelMedium?.copyWith(
        color: AppPalette.inkLight,
        letterSpacing: 0.6,
      ),
    );
  }
}
