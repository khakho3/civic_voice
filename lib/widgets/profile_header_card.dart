import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The identity block at the top of every module's profile screen —
/// avatar (a real photo when [photoPath] is set, initials otherwise),
/// name, and optional subtitle/pills. Bare (no card border): a profile
/// hero reads as the page's own identity, not a boxed section like the
/// grouped info below it — matching the majority of this app's profile
/// screens (Municipal/Maintenance) rather than the one bordered outlier
/// (Admin's old `_ProfileCard`).
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    this.subtitle,
    this.pills = const [],
    this.editing = false,
    this.onEditPhoto,
    this.photoPath,
    this.photoUpdating = false,
  });

  final String name;

  /// Plain descriptive text under the name (e.g. "Administrator account").
  /// Mutually usable alongside [pills] — some screens want both.
  final String? subtitle;

  /// Small tinted chips under the name/subtitle (e.g. "Verified Official",
  /// "ID #1234").
  final List<Widget> pills;

  /// Unused internally — the camera badge now shows whenever [onEditPhoto]
  /// is actually wired up, regardless of edit-mode state (a couple of
  /// screens previously passed `editing: true` with no [onEditPhoto],
  /// which rendered a decorative badge that did nothing when tapped).
  /// Kept as a no-op param so existing call sites don't need updating.
  final bool editing;
  final VoidCallback? onEditPhoto;

  /// A real profile photo — network URL (starts with "http") or a local
  /// file path. Null falls back to initials. Only Citizen currently has a
  /// real photo picker wired up; every other module stays initials-only.
  final String? photoPath;

  /// Shows a loading spinner over the avatar while a picked photo uploads.
  final bool photoUpdating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty ? '' : part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: photoPath == null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            initials,
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : photoPath!.startsWith('http')
                      ? Image.network(photoPath!, fit: BoxFit.cover)
                      : Image.file(File(photoPath!), fit: BoxFit.cover),
                ),
              ),
              if (photoUpdating)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (onEditPhoto != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: CircleBorder(
                      side: BorderSide(color: colorScheme.surface, width: 2),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEditPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          AppIcons.camera,
                          size: AppIconSize.sm,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (pills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: pills,
            ),
          ],
        ],
      ),
    );
  }
}
