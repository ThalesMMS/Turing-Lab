//
//  settings_page.dart
//  Turing Lab
//
//  Generates the settings page loading persisted preferences,
//  displaying appearance and general controls while
//  saving changes via shared repository with responsive user feedback.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/core/utils/epsilon_utils.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';
import 'package:turing_lab/presentation/pages/about_page.dart';
import 'package:turing_lab/presentation/providers/empty_string_symbol_provider.dart';
import 'package:turing_lab/presentation/providers/settings_provider.dart';
import 'package:turing_lab/presentation/widgets/app_snackbar.dart';
import 'package:turing_lab/presentation/widgets/switch_setting_tile.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.repository});

  final SettingsRepository? repository;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoading = false;
  SettingsModel _settings = const SettingsModel();

  SettingsRepository get _repository =>
      widget.repository ?? ref.read(settingsRepositoryProvider);

  TextStyle? _settingTitleStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
  }

  TextStyle? _settingSubtitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  bool _useStackedControlLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return constraints.maxWidth / textScale < 360;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _repository.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
      await ref.read(settingsProvider.notifier).refreshFromModel(settings);
    } catch (error, stackTrace) {
      debugPrint('Failed to load settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AppLocalizations.of(context).settingsLoadError);
    }
  }

  Future<void> _saveSettings() async {
    final currentSettings = _settings;

    try {
      await _repository.saveSettings(currentSettings);
      await ref
          .read(settingsProvider.notifier)
          .refreshFromModel(currentSettings);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: AppLocalizations.of(context).settingsSaveSuccess,
        tone: AppSnackBarTone.success,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to save settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(AppLocalizations.of(context).settingsSaveError);
    }
  }

  Future<void> _resetToDefaults() async {
    final previousSettings = _settings;
    final previousEmptyStringSymbol = ref.read(emptyStringSymbolProvider);
    const defaults = SettingsModel();

    setState(() {
      _settings = defaults;
    });

    try {
      await ref.read(emptyStringSymbolProvider.notifier).reset();
      try {
        await _repository.saveSettings(defaults);
      } catch (_) {
        await ref
            .read(emptyStringSymbolProvider.notifier)
            .setSymbol(previousEmptyStringSymbol);
        rethrow;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to reset settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _settings = previousSettings;
      });
      await ref
          .read(settingsProvider.notifier)
          .refreshFromModel(previousSettings);
      if (!mounted) return;
      _showError(AppLocalizations.of(context).settingsSaveError);
      return;
    }

    try {
      await ref.read(settingsProvider.notifier).refreshFromModel(defaults);
    } catch (error, stackTrace) {
      debugPrint('Failed to apply reset settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(AppLocalizations.of(context).settingsApplyError);
      return;
    }

    if (!mounted) return;
    showAppSnackBar(
      context,
      message: AppLocalizations.of(context).settingsResetSuccess,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _changeLanguage(String localeCode) async {
    final previousSettings = _settings;
    final updatedSettings = _settings.copyWith(localeCode: localeCode);

    setState(() {
      _settings = updatedSettings;
    });
    await ref.read(settingsProvider.notifier).refreshFromModel(updatedSettings);

    try {
      await _repository.saveSettings(updatedSettings);
    } catch (error, stackTrace) {
      debugPrint('Failed to save settings: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _settings = previousSettings;
      });
      await ref
          .read(settingsProvider.notifier)
          .refreshFromModel(previousSettings);
      if (!mounted) return;
      _showError(AppLocalizations.of(context).settingsSaveError);
    }
  }

  void _showError(String message) {
    showAppSnackBar(context, message: message, tone: AppSnackBarTone.error);
  }

  Future<void> _setEmptyStringSymbol(String value) async {
    try {
      await ref.read(emptyStringSymbolProvider.notifier).setSymbol(value);
    } catch (error, stackTrace) {
      debugPrint('Failed to save empty-string notation: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showError(AppLocalizations.of(context).settingsSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPageTitle),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: l10n.settingsSaveTooltip,
          ),
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            tooltip: l10n.settingsResetTooltip,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(l10n.settingsSectionTheme),
              _buildThemeSettings(l10n),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.settingsSectionLanguage),
              _buildLanguageSettings(l10n),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.settingsSectionCanvas),
              _buildCanvasSettings(l10n),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.settingsSectionGeneral),
              _buildGeneralSettings(l10n),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.settingsSectionAbout),
              _buildAboutSettings(l10n),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.settingsSectionActions),
              _buildActionButtons(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemeSettings(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleSetting(
              l10n.settingsThemeModeTitle,
              l10n.settingsThemeModeDescription,
              _settings.themeMode,
              [
                (
                  value: 'system',
                  label: l10n.settingsThemeSystem,
                  key: const ValueKey('settings_theme_system'),
                ),
                (
                  value: 'light',
                  label: l10n.settingsThemeLight,
                  key: const ValueKey('settings_theme_light'),
                ),
                (
                  value: 'dark',
                  label: l10n.settingsThemeDark,
                  key: const ValueKey('settings_theme_dark'),
                ),
              ],
              (value) {
                setState(() {
                  _settings = _settings.copyWith(themeMode: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings(AppLocalizations l10n) {
    final activeLocaleCode =
        _settings.localeCode ?? Localizations.localeOf(context).languageCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSimpleSetting(
          l10n.settingsLanguageTitle,
          l10n.settingsLanguageDescription,
          activeLocaleCode,
          [
            (
              value: 'en',
              label: l10n.settingsLanguageEnglish,
              key: const ValueKey('settings_language_en'),
            ),
            (
              value: 'pt',
              label: l10n.settingsLanguagePortuguese,
              key: const ValueKey('settings_language_pt'),
            ),
          ],
          (value) async {
            await _changeLanguage(value);
          },
        ),
      ),
    );
  }

  Widget _buildCanvasSettings(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchSettingTile(
              title: l10n.settingsShowGridTitle,
              subtitle: l10n.settingsShowGridDescription,
              value: _settings.showGrid,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(showGrid: value);
                });
              },
              switchKey: const ValueKey('settings_show_grid_switch'),
            ),
            const SizedBox(height: 16),
            SwitchSettingTile(
              title: l10n.settingsShowCoordinatesTitle,
              subtitle: l10n.settingsShowCoordinatesDescription,
              value: _settings.showCoordinates,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(showCoordinates: value);
                });
              },
              switchKey: const ValueKey('settings_show_coordinates_switch'),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              l10n.settingsGridSizeTitle,
              l10n.settingsGridSizeDescription,
              _settings.gridSize,
              10.0,
              50.0,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(gridSize: value);
                });
              },
              sliderKey: const ValueKey('settings_grid_size_slider'),
            ),
            _buildSliderSetting(
              l10n.settingsNodeSizeTitle,
              l10n.settingsNodeSizeDescription,
              _settings.nodeSize,
              20.0,
              60.0,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(nodeSize: value);
                });
              },
              sliderKey: const ValueKey('settings_node_size_slider'),
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              l10n.settingsFontSizeTitle,
              l10n.settingsFontSizeDescription,
              _settings.fontSize,
              12.0,
              20.0,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(fontSize: value);
                });
              },
              sliderKey: const ValueKey('settings_font_size_slider'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(AppLocalizations l10n) {
    final emptyStringSymbol = ref.watch(emptyStringSymbolProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleSetting(
              l10n.settingsEmptyStringNotationTitle,
              l10n.settingsEmptyStringNotationDescription,
              emptyStringSymbol,
              const [
                (
                  value: kEpsilonSymbol,
                  label: kEpsilonSymbol,
                  key: ValueKey('settings_empty_string_epsilon'),
                ),
                (
                  value: kLambdaSymbol,
                  label: kLambdaSymbol,
                  key: ValueKey('settings_empty_string_lambda'),
                ),
              ],
              (value) {
                unawaited(_setEmptyStringSymbol(value));
              },
              semanticLabels: {
                kEpsilonSymbol: l10n.emptyStringEpsilon,
                kLambdaSymbol: l10n.emptyStringLambda,
              },
            ),
            const SizedBox(height: 16),
            SwitchSettingTile(
              title: l10n.settingsAutoSaveTitle,
              subtitle: l10n.settingsAutoSaveDescription,
              value: _settings.autoSave,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(autoSave: value);
                });
              },
              switchKey: const ValueKey('settings_auto_save_switch'),
            ),
            const SizedBox(height: 16),
            SwitchSettingTile(
              title: l10n.settingsShowTooltipsTitle,
              subtitle: l10n.settingsShowTooltipsDescription,
              value: _settings.showTooltips,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(showTooltips: value);
                });
              },
              switchKey: const ValueKey('settings_show_tooltips_switch'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSettings(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        key: const ValueKey('settings_about_tile'),
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.settingsAboutTileTitle),
        subtitle: Text(l10n.settingsAboutTileSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const AboutPage()),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: Text(l10n.settingsSaveTooltip),
                key: const ValueKey('settings_save_button'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: Text(l10n.settingsResetTooltip),
                key: const ValueKey('settings_reset_button'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSetting(
    String title,
    String subtitle,
    String currentValue,
    List<({String value, String label, Key key})> options,
    ValueChanged<String> onChanged, {
    Map<String, String> semanticLabels = const {},
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _settingTitleStyle(context)),
        const SizedBox(height: 4),
        Text(subtitle, style: _settingSubtitleStyle(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              key: option.key,
              label: Semantics(
                label: semanticLabels[option.value],
                excludeSemantics: semanticLabels.containsKey(option.value),
                child: Text(option.label),
              ),
              selected: option.value == currentValue,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option.value);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    Key? sliderKey,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = _useStackedControlLayout(context, constraints);
        final slider = Slider(
          key: sliderKey,
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          label: value.round().toString(),
          onChanged: onChanged,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _settingTitleStyle(context)),
            const SizedBox(height: 4),
            Text(subtitle, style: _settingSubtitleStyle(context)),
            const SizedBox(height: 8),
            if (useStackedLayout) ...[
              slider,
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value.round().toString(),
                  style: _settingTitleStyle(context),
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(child: slider),
                  const SizedBox(width: 16),
                  Text(
                    value.round().toString(),
                    style: _settingTitleStyle(context),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
