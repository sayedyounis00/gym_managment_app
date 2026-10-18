import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/widgets/image_preview_dialog.dart';

class MemberAvatar extends StatefulWidget {
  final String? photoPath;
  final File? photoFile;
  final String name;
  final double size;
  final bool enablePreview;
  final VoidCallback? onTap;

  const MemberAvatar({
    super.key,
    this.photoPath,
    this.photoFile,
    required this.name,
    this.size = 48.0,
    this.enablePreview = false,
    this.onTap,
  });

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar> {
  File? _resolvedFile;

  @override
  void initState() {
    super.initState();
    _resolvePhoto();
  }

  @override
  void didUpdateWidget(covariant MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath || oldWidget.photoFile != widget.photoFile) {
      _resolvePhoto();
    }
  }

  Future<void> _resolvePhoto() async {
    if (widget.photoFile != null) {
      if (mounted) setState(() => _resolvedFile = widget.photoFile);
      return;
    }

    if (widget.photoPath != null && widget.photoPath!.isNotEmpty) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/${widget.photoPath!}');
        if (await file.exists()) {
          if (mounted) setState(() => _resolvedFile = file);
          return;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _resolvedFile = null);
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]} ${parts[1][0]}';
    }
    return clean.isNotEmpty ? clean[0] : '';
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    if (_resolvedFile != null) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.file(
          _resolvedFile!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    } else {
      avatarWidget = _buildFallback();
    }

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }

    final hasPhoto = _resolvedFile != null ||
        (widget.photoPath != null && widget.photoPath!.isNotEmpty) ||
        widget.photoFile != null;

    if (widget.enablePreview && hasPhoto) {
      return InkWell(
        onTap: () {
          ImagePreviewDialog.show(
            context,
            file: _resolvedFile ?? widget.photoFile,
            imagePath: widget.photoPath,
            title: widget.name.isNotEmpty ? widget.name : 'صورة المشترك',
          );
        },
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback() {
    final initials = _getInitials(widget.name);
    final fontSize = widget.size * 0.38;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primaryDark,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
