import 'package:cricket_scorer_pro/core/localization/app_localizations.dart';
import 'package:cricket_scorer_pro/core/localization/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String selected = 'en';

  Future<void> _continue() async {
    await ref.read(localeProvider.notifier).setLocale(Locale(selected));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.translate,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Choose your language',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'अपनी भाषा चुनें • உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 560
                          ? 2
                          : 1,
                      childAspectRatio: 4.6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: AppLocalizations.languageNames.length,
                    itemBuilder: (context, index) {
                      final entry = AppLocalizations.languageNames.entries
                          .elementAt(index);
                      final active = selected == entry.key;
                      return Card(
                        color: active
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(
                            entry.value,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: active
                              ? const Icon(Icons.check_circle)
                              : const Icon(Icons.circle_outlined),
                          onTap: () => setState(() => selected = entry.key),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _continue,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      AppLocalizations(Locale(selected)).text('continue'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
