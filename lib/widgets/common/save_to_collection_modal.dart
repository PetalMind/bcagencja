import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/state/models/property_model.dart';
import '../../core/state/models/saved_offer_model.dart';
import '../../core/state/providers/smart_favorites_provider.dart';
import '../../core/state/providers/notification_preferences_provider.dart';
import 'custom_button.dart';

/// Modal „Zapisz do kolekcji”: wybór kolekcji, notatka, powiadomienia.
/// Po kliknięciu „Zapisz” wywołuje smartFavoritesProvider.saveOffer i zamyka.
void showSaveToCollectionModal({
  required BuildContext context,
  required Property property,
  SavedOfferEntry? existingEntry,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SaveToCollectionSheet(
      property: property,
      existingEntry: existingEntry,
    ),
  );
}

class _SaveToCollectionSheet extends ConsumerStatefulWidget {
  const _SaveToCollectionSheet({
    required this.property,
    this.existingEntry,
  });

  final Property property;
  final SavedOfferEntry? existingEntry;

  @override
  ConsumerState<_SaveToCollectionSheet> createState() => _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends ConsumerState<_SaveToCollectionSheet> {
  late Set<String> _selectedCollectionIds;
  late TextEditingController _noteController;
  bool _notifyPriceChange = false;
  bool _notifyNewDocs = false;
  bool _notifyOthersView = false;
  bool _showNewCollection = false;
  String _newCollectionName = '';
  String _newCollectionIcon = '📁';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCollectionIds = Set.from(widget.existingEntry?.collectionIds ?? []);
    _noteController = TextEditingController(text: widget.existingEntry?.note ?? '');
    _notifyPriceChange = widget.existingEntry?.notifyPriceChange ?? false;
    _notifyNewDocs = widget.existingEntry?.notifyNewDocs ?? false;
    _notifyOthersView = widget.existingEntry?.notifyOthersView ?? false;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    List<String> collectionIds = _selectedCollectionIds.toList();
    if (_showNewCollection && _newCollectionName.trim().isNotEmpty) {
      final id = 'custom_${_newCollectionName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';
      await ref.read(smartFavoritesProvider.notifier).addCollection(
            SavedCollection(id: id, name: _newCollectionName.trim(), icon: _newCollectionIcon),
          );
      collectionIds = [...collectionIds, id];
    }
    setState(() => _saving = true);
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final notifier = ref.read(smartFavoritesProvider.notifier);
    if (widget.existingEntry != null) {
      await notifier.updateEntry(
        widget.existingEntry!.copyWith(
          collectionIds: collectionIds,
          note: note,
          notifyPriceChange: _notifyPriceChange,
          notifyNewDocs: _notifyNewDocs,
          notifyOthersView: _notifyOthersView,
        ),
      );
    } else {
      await notifier.saveOffer(
        propertyId: widget.property.id,
        collectionIds: collectionIds,
        note: note,
        notifyPriceChange: _notifyPriceChange,
        notifyNewDocs: _notifyNewDocs,
        notifyOthersView: _notifyOthersView,
        ownerId: widget.property.ownerId,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEntry != null ? 'Zapisano zmiany' : 'Oferta zapisana'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final smart = ref.watch(smartFavoritesProvider);
    final collections = smart.collections;
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(AppIcons.favorites, color: AppColors.accent, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Zapisz do kolekcji',
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolekcje
                  Text(
                    'Kolekcje',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...collections.map((c) {
                    final count = ref.read(smartFavoritesProvider.notifier).countInCollection(c.id);
                    final selected = _selectedCollectionIds.contains(c.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedCollectionIds.add(c.id);
                          } else {
                            _selectedCollectionIds.remove(c.id);
                          }
                        });
                      },
                      title: Row(
                        children: [
                          Text(c.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${c.name} ($count)',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  if (_showNewCollection) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _newCollectionIcon,
                          items: ['📁', '🔥', '💼', '📊', '🤔', '⭐', '🏷️']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _newCollectionIcon = v ?? '📁'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Nazwa kolekcji',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _newCollectionName = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => setState(() => _showNewCollection = !_showNewCollection),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(_showNewCollection ? 'Anuluj nową kolekcję' : 'Utwórz nową kolekcję...'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  // Notatka
                  Text(
                    'Notatka (opcjonalnie)',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Np. Czekam na analizę techniczną',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  // Powiadomienia
                  Text(
                    'Powiadom mnie gdy:',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: _notifyPriceChange,
                    onChanged: (v) => setState(() => _notifyPriceChange = v ?? false),
                    title: const Text('Zmieni się cena'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _notifyNewDocs,
                    onChanged: (v) => setState(() => _notifyNewDocs = v ?? false),
                    title: const Text('Pojawią się nowe dokumenty'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _notifyOthersView,
                    onChanged: (v) => setState(() => _notifyOthersView = v ?? false),
                    title: const Text('Ktoś inny ogląda tę ofertę'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Powiadomienia w aplikacji',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  SwitchListTile(
                    value: ref.watch(notificationPreferencesProvider).pushEnabled,
                    onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setPushEnabled(v),
                    title: const Text('Push (aplikacja)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: ref.watch(notificationPreferencesProvider).emailEnabled,
                    onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setEmailEnabled(v),
                    title: const Text('E-mail'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.lg),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Anuluj',
                    variant: ButtonVariant.outlined,
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CustomButton(
                    label: 'Zapisz',
                    icon: Icons.check,
                    onPressed: _saving ? null : _onSave,
                    isLoading: _saving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
