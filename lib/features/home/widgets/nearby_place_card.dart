import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../places_user/user_place_model.dart';
import '../models/home_models.dart';

class NearbyPlaceCard extends StatelessWidget {
  const NearbyPlaceCard({
    super.key,
    required this.place,
    this.showAddButton = false,
    this.onAddPressed,
  });

  final NearbyPlace place;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showAddButton) {
      debugPrint(
        'NearbyPlaceCard: add button ${onAddPressed == null ? 'disabled' : 'enabled'} '
        'for "${place.name}" (onPressed ${onAddPressed == null ? 'null' : 'set'}).',
      );
    }

    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(place.icon, color: AppColors.ink, size: 16),
              ),
              if (place.isUserPlace) ...<Widget>[
                const SizedBox(width: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.95),
                        ),
                      ),
                      child: Text(
                        'Ton lieu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            place.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            place.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            place.distance,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (place.recommendationReason != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              place.recommendationReason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
          if (place.socialProofCount > 0) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _buildAddedCountLabel(place.socialProofCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (place.popularMoodTag != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'Populaire pour : ${UserPlaceOptions.labelForMood(place.popularMoodTag!)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                fontSize: 11,
              ),
            ),
          ],
          if (showAddButton) ...<Widget>[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAddPressed,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.white.withValues(alpha: 0.45),
                  foregroundColor: AppColors.ink,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.95),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildAddedCountLabel(int socialProofCount) {
    if (socialProofCount <= 1) {
      return 'Ajoute 1 fois';
    }

    return 'Ajoute $socialProofCount fois';
  }
}
