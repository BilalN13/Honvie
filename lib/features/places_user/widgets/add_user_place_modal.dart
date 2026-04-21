import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/models/home_models.dart';
import '../../places/place_metadata.dart';
import '../user_place_model.dart';

class AddUserPlaceModal extends StatefulWidget {
  const AddUserPlaceModal({super.key, required this.place});

  final NearbyPlace place;

  @override
  State<AddUserPlaceModal> createState() => _AddUserPlaceModalState();
}

class _AddUserPlaceModalState extends State<AddUserPlaceModal> {
  late final TextEditingController _nameController;
  late String _selectedType;
  final Set<String> _selectedMoodTags = <String>{};
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _selectedType = _resolveInitialType(widget.place);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _resolveInitialType(NearbyPlace place) {
    for (final candidate in PlaceMetadata.selectableTypes) {
      if (place.types.contains(candidate)) {
        return candidate;
      }
    }

    return PlaceMetadata.selectableTypes.first;
  }

  void _toggleMood(String moodTag, bool shouldSelect) {
    setState(() {
      if (shouldSelect) {
        _selectedMoodTags.add(moodTag);
      } else {
        _selectedMoodTags.remove(moodTag);
      }
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    final latitude = widget.place.latitude;
    final longitude = widget.place.longitude;

    if (name.isEmpty ||
        _selectedMoodTags.isEmpty ||
        latitude == null ||
        longitude == null) {
      setState(() {
        _showValidation = true;
      });
      return;
    }

    Navigator.of(context).pop(
      UserPlaceDraft(
        name: name,
        type: _selectedType,
        moodTags: _selectedMoodTags.toList()..sort(),
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Ajouter un lieu', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Enregistre ce lieu avec un type et des moods pour affiner tes recommandations.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  errorText:
                      _showValidation && _nameController.text.trim().isEmpty
                      ? 'Renseigne un nom.'
                      : null,
                  filled: true,
                  fillColor: AppColors.warmCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: PlaceMetadata.selectableTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(PlaceMetadata.labelForType(type)),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Type',
                  filled: true,
                  fillColor: AppColors.warmCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Moods', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserPlaceOptions.moodTags.map((String moodTag) {
                  final isSelected = _selectedMoodTags.contains(moodTag);

                  return FilterChip(
                    label: Text(UserPlaceOptions.labelForMood(moodTag)),
                    selected: isSelected,
                    onSelected: (bool value) => _toggleMood(moodTag, value),
                    backgroundColor: AppColors.warmCream,
                    selectedColor: AppColors.primaryPink.withValues(
                      alpha: 0.28,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryOrange
                          : AppColors.border,
                    ),
                    checkmarkColor: AppColors.ink,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              if (_showValidation && _selectedMoodTags.isEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Selectionne au moins un mood.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.95),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: AppColors.softBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
