import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../core/services/submission_document_service.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../input_formatters.dart';
import '../listing_submission_model.dart';

/// Dopuszczalne formaty dla dokumentów (PDF, DOC, DOCX).
final List<FileFormat> _documentFileFormats = [
  Formats.pdf,
  Formats.plainTextFile,
  Formats.webUnknown,
];

/// Dopuszczalne formaty dla zdjęć (obrazy).
final List<FileFormat> _photoFileFormats = [
  Formats.png,
  Formats.jpeg,
];

const List<String> _documentExtensions = ['pdf', 'doc', 'docx'];
const List<String> _photoExtensions = ['jpg', 'jpeg', 'png'];

bool _isDocument(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return _documentExtensions.contains(ext);
}

bool _isPhoto(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return _photoExtensions.contains(ext);
}

/// Krok 5: Dokumentacja – opcjonalnie, przycisk "Pomiń ten krok".
/// Obsługuje: drag & drop (super_drag_and_drop), file picker, dodawanie wielu plików,
/// zmianę nazwy, usuwanie. Upload do Firebase Storage.
class Step5Documentation extends ConsumerStatefulWidget {
  const Step5Documentation({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.readOnly = false,
  });

  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  final bool readOnly;

  @override
  ConsumerState<Step5Documentation> createState() => _Step5DocumentationState();
}

class _Step5DocumentationState extends ConsumerState<Step5Documentation> {
  bool _isDropOverDocuments = false;
  bool _isDropOverPhotos = false;
  bool _isUploadingDocuments = false;
  bool _isUploadingPhotos = false;
  String? _uploadErrorDocuments;
  String? _uploadErrorPhotos;

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  Future<void> _pickFiles({required bool documents}) async {
    final extensions =
        documents ? _documentExtensions : _photoExtensions;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      if (documents) {
        _isUploadingDocuments = true;
        _uploadErrorDocuments = null;
      } else {
        _isUploadingPhotos = true;
        _uploadErrorPhotos = null;
      }
    });
    var addedCount = 0;
    for (final platformFile in result.files) {
      Uint8List? bytes = platformFile.bytes;
      if (bytes == null && platformFile.path != null) {
        try {
          bytes = await XFile(platformFile.path!).readAsBytes();
        } catch (_) {
          continue;
        }
      }
      if (bytes != null &&
          platformFile.name.isNotEmpty &&
          (documents ? _isDocument : _isPhoto)(platformFile.name)) {
        try {
          final attachment = await _uploadFile(bytes, platformFile.name);
          if (attachment != null && mounted) {
            widget.formData.attachments.add(attachment);
            addedCount++;
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              if (documents) {
                _uploadErrorDocuments = e.toString().replaceFirst('Exception: ', '');
              } else {
                _uploadErrorPhotos = e.toString().replaceFirst('Exception: ', '');
              }
            });
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _isUploadingDocuments = false;
        _isUploadingPhotos = false;
      });
      widget.onDataChanged(widget.formData);
      if (addedCount > 0) {
        _showSuccessSnackBar(
          addedCount == 1
              ? 'Plik został dodany'
              : 'Dodano $addedCount plików',
        );
      }
    }
  }

  Future<SubmissionAttachment?> _uploadFile(Uint8List bytes, String filename) async {
    final service = ref.read(submissionDocumentServiceProvider);
    return service.upload(bytes: bytes, filename: filename);
  }

  void _deleteAttachment(int index) {
    widget.formData.attachments.removeAt(index);
    widget.onDataChanged(widget.formData);
    setState(() {});
  }

  Future<void> _renameAttachment(int index) async {
    final att = widget.formData.attachments[index];
    final controller = TextEditingController(text: att.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zmień nazwę pliku'),
        content: TextField(
          controller: controller,
          maxLength: kMaxFileNameLength,
          decoration: const InputDecoration(
            hintText: 'Nazwa pliku',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim().isNotEmpty ? v.trim() : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              Navigator.of(ctx).pop(v.isNotEmpty ? v : null);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      widget.formData.attachments[index] = SubmissionAttachment(
        displayName: newName,
        storagePath: att.storagePath,
        downloadUrl: att.downloadUrl,
      );
      widget.onDataChanged(widget.formData);
      setState(() {});
    }
  }

  Future<void> _handleDrop(PerformDropEvent event, {required bool documents}) async {
    if (mounted) {
      setState(() {
        if (documents) {
          _isUploadingDocuments = true;
          _uploadErrorDocuments = null;
        } else {
          _isUploadingPhotos = true;
          _uploadErrorPhotos = null;
        }
      });
    }
    final formats = documents ? _documentFileFormats : _photoFileFormats;
    final service = ref.read(submissionDocumentServiceProvider);
    var addedCount = 0;
    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (reader == null) continue;
      final suggestedName = await reader.getSuggestedName() ?? 'plik';
      if (documents && !_isDocument(suggestedName)) continue;
      if (!documents && !_isPhoto(suggestedName)) continue;
      Uint8List? bytes;
      for (final format in formats) {
        if (reader.canProvide(format)) {
          final completer = Completer<Uint8List?>();
          reader.getFile(format, (file) async {
            try {
              final data = await file.readAll();
              completer.complete(data);
            } catch (e) {
              completer.complete(null);
            }
          }, onError: (e) {
            completer.complete(null);
          });
          bytes = await completer.future;
          if (bytes != null && bytes.isNotEmpty) break;
        }
      }
      if (bytes != null && bytes.isNotEmpty) {
        try {
          final attachment =
              await service.upload(bytes: bytes, filename: suggestedName);
          if (!mounted) return;
          widget.formData.attachments.add(attachment);
          addedCount++;
        } catch (e) {
          if (mounted) {
            setState(() {
              if (documents) {
                _uploadErrorDocuments = e.toString().replaceFirst('Exception: ', '');
              } else {
                _uploadErrorPhotos = e.toString().replaceFirst('Exception: ', '');
              }
            });
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _isUploadingDocuments = false;
        _isUploadingPhotos = false;
      });
      widget.onDataChanged(widget.formData);
      if (addedCount > 0) {
        _showSuccessSnackBar(
          addedCount == 1
              ? 'Plik został dodany'
              : 'Dodano $addedCount plików',
        );
      }
    }
  }

  DropOperation _onDropOver(DropOverEvent event, {required bool documents}) {
    if (event.session.items.isEmpty) return DropOperation.none;
    final formats = documents ? _documentFileFormats : _photoFileFormats;
    final hasFile = event.session.items.any((item) {
      final reader = item.dataReader;
      if (reader == null) return false;
      for (final f in formats) {
        if (reader.canProvide(f)) return true;
      }
      return false;
    });
    return hasFile ? DropOperation.copy : DropOperation.none;
  }

  List<(int, SubmissionAttachment)> get _documentEntries {
    final list = <(int, SubmissionAttachment)>[];
    for (var i = 0; i < widget.formData.attachments.length; i++) {
      if (_isDocument(widget.formData.attachments[i].displayName)) {
        list.add((i, widget.formData.attachments[i]));
      }
    }
    return list;
  }

  List<(int, SubmissionAttachment)> get _photoEntries {
    final list = <(int, SubmissionAttachment)>[];
    for (var i = 0; i < widget.formData.attachments.length; i++) {
      if (_isPhoto(widget.formData.attachments[i].displayName)) {
        list.add((i, widget.formData.attachments[i]));
      }
    }
    return list;
  }

  Widget _buildDropZone({
    required bool forDocuments,
    required bool isDropOver,
  }) {
    final formats = forDocuments ? _documentFileFormats : _photoFileFormats;
    final formatsStr = forDocuments
        ? 'PDF, DOC, DOCX'
        : 'JPG, PNG';
    final isUploading = forDocuments ? _isUploadingDocuments : _isUploadingPhotos;
    final uploadError = forDocuments ? _uploadErrorDocuments : _uploadErrorPhotos;

    return DropRegion(
      formats: formats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (e) {
        final op = _onDropOver(e, documents: forDocuments);
        setState(() {
          if (forDocuments) {
            _isDropOverDocuments = op != DropOperation.none;
          } else {
            _isDropOverPhotos = op != DropOperation.none;
          }
        });
        return op;
      },
      onDropEnter: (_) => setState(() {
        if (forDocuments) {
          _isDropOverDocuments = true;
        } else {
          _isDropOverPhotos = true;
        }
      }),
      onDropLeave: (_) => setState(() {
        if (forDocuments) {
          _isDropOverDocuments = false;
        } else {
          _isDropOverPhotos = false;
        }
      }),
      onPerformDrop: (e) => _handleDrop(e, documents: forDocuments),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUploading ? null : () => _pickFiles(documents: forDocuments),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          splashColor: AppColors.accent.withValues(alpha: 0.1),
          highlightColor: AppColors.accent.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxl,
              horizontal: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: isDropOver
                  ? AppColors.accent.withValues(alpha: 0.06)
                  : (isUploading
                      ? AppColors.grey100
                      : AppColors.grey50),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDropOver
                    ? AppColors.accent
                    : (uploadError != null
                        ? AppColors.error.withValues(alpha: 0.5)
                        : AppColors.borderLight),
                width: isDropOver ? 2.5 : 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: isDropOver
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isUploading
                      ? Column(
                          key: const ValueKey('loading'),
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Przesyłanie…',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('idle'),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: (isDropOver
                                        ? AppColors.accent
                                        : AppColors.grey200)
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDropOver
                                    ? Icons.cloud_upload_rounded
                                    : (forDocuments
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.add_photo_alternate_rounded),
                                size: 44,
                                color: isDropOver
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              isDropOver
                                  ? 'Upuść pliki tutaj'
                                  : 'Przeciągnij pliki lub kliknij, by wybrać',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isDropOver
                                    ? AppColors.accent
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$formatsStr • maks. 10 MB na plik',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                if (uploadError != null && uploadError.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            uploadError,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masz już dokumentację?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Możesz załączyć dokumenty i zdjęcia (opcjonalnie – możesz wysłać je później):',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Sekcja: Dokumenty
          Text(
            'Dokumenty',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          _bullet('Wypis z KW'),
          _bullet('Umowa najmu (jeśli dotyczy)'),
          _bullet('MPZP / Warunki zabudowy'),
          _bullet('Operat szacunkowy (jeśli posiadasz)'),
          const SizedBox(height: AppSpacing.md),
          if (!widget.readOnly)
            _buildDropZone(
              forDocuments: true,
              isDropOver: _isDropOverDocuments,
            ),
          if (!widget.readOnly) const SizedBox(height: AppSpacing.sm),
          Text(
            'Załączone dokumenty (${_documentEntries.length}):',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_documentEntries.isEmpty)
            _EmptyAttachmentState(
              icon: Icons.folder_open_rounded,
              message: 'Nie dodano jeszcze żadnych dokumentów',
            )
          else
            ..._documentEntries.map((entry) => _AttachmentChip(
                  attachment: entry.$2,
                  isPhoto: false,
                  readOnly: widget.readOnly,
                  onRename: () => _renameAttachment(entry.$1),
                  onDelete: () => _deleteAttachment(entry.$1),
                )),
          const SizedBox(height: AppSpacing.xxl),
          // Sekcja: Zdjęcia
          Text(
            'Zdjęcia',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          _bullet('Zdjęcia nieruchomości (fasada, wnętrza, działka)'),
          const SizedBox(height: AppSpacing.md),
          if (!widget.readOnly)
            _buildDropZone(
              forDocuments: false,
              isDropOver: _isDropOverPhotos,
            ),
          if (!widget.readOnly) const SizedBox(height: AppSpacing.sm),
          Text(
            'Załączone zdjęcia (${_photoEntries.length}):',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_photoEntries.isEmpty)
            _EmptyAttachmentState(
              icon: Icons.photo_library_outlined,
              message: 'Nie dodano jeszcze żadnych zdjęć',
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _photoEntries.map((entry) => _PhotoAttachmentCard(
                attachment: entry.$2,
                readOnly: widget.readOnly,
                onRename: () => _renameAttachment(entry.$1),
                onDelete: () => _deleteAttachment(entry.$1),
              )).toList(),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nie chcemy stracić leada z powodu braku dokumentów – możesz uzupełnić później w kontakcie z agentem.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAttachmentState extends StatelessWidget {
  const _EmptyAttachmentState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textDisabled),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.attachment,
    required this.isPhoto,
    this.readOnly = false,
    this.onRename,
    this.onDelete,
  });

  final SubmissionAttachment attachment;
  final bool isPhoto;
  final bool readOnly;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        elevation: 0,
        child: InkWell(
          onTap: readOnly ? null : onRename,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(
                    isPhoto ? Icons.image_outlined : Icons.description_outlined,
                    size: 22,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    attachment.displayName,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!readOnly) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onRename,
                    tooltip: 'Zmień nazwę',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Usuń',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(36, 36),
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura zdjęcia – używa [SubmissionAttachment.downloadUrl] gdy jest dostępny.
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.attachment});

  final SubmissionAttachment attachment;

  static Widget _placeholder() {
    return Container(
      color: AppColors.grey200,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = attachment.downloadUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }
    return FutureBuilder<String>(
      future: FirebaseStorage.instance
          .ref()
          .child(attachment.storagePath)
          .getDownloadURL(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _placeholder(),
            errorWidget: (context, url, error) => _placeholder(),
          );
        }
        return _placeholder();
      },
    );
  }
}

class _PhotoAttachmentCard extends StatelessWidget {
  const _PhotoAttachmentCard({
    required this.attachment,
    this.readOnly = false,
    this.onRename,
    this.onDelete,
  });

  final SubmissionAttachment attachment;
  final bool readOnly;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Material(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        elevation: 0,
        child: InkWell(
          onTap: readOnly ? null : onRename,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Miniatura zdjęcia nad nazwą
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _PhotoThumbnail(attachment: attachment),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        attachment.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    if (!readOnly)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        onSelected: (value) {
                          if (value == 'rename') onRename?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Zmień nazwę'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Usuń', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
