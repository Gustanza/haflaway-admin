import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const _foldersSub = 'galleryFolders';
const _mediaSub   = 'media';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg    = Color(0xFF111114);
  static const card  = Color(0xFF1C1C1E);
  static const card2 = Color(0xFF28282C);
  static const card3 = Color(0xFF3A3A3C);
  static const sep   = Color(0xFF2C2C2E);
  static const lime  = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const lbl1  = Color(0xFFEEEEF0);
  static const lbl3  = Color(0xFF8E8E93);
  static const lbl4  = Color(0xFF48484A);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EventGallery — folder list view
// ─────────────────────────────────────────────────────────────────────────────

class EventGallery extends StatefulWidget {
  final Event event;
  const EventGallery({super.key, required this.event});

  @override
  State<EventGallery> createState() => _EventGalleryState();
}

class _EventGalleryState extends State<EventGallery> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _foldersRef =>
      _firestore.collection(ecol).doc(widget.event.id).collection(_foldersSub);

  Future<void> _showCreateFolderDialog() async {
    final name = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.90, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => const _CreateFolderDialog(),
    );

    if (name == null || name.trim().isEmpty) return;
    try {
      await _foldersRef.add({
        'name':      name.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': _auth.currentUser?.uid ?? '',
      });
    } catch (e) {
      showToast(isGood: false, msg: 'Failed to create folder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            const Positioned(top: -80, right: -80,
                child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11)),
            const Positioned(bottom: -40, left: -80,
                child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06)),

            CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: SafeArea(bottom: false, child: _topBar())),
                SliverToBoxAdapter(child: _header()),
                _foldersList(),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ),
              ],
            ),

            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: GestureDetector(
                onTap: _showCreateFolderDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: _T.lime,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(
                      color: _T.lime.withValues(alpha: 0.35),
                      blurRadius: 18, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.create_new_folder_rounded, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text('New Folder',
                          style: _T.f(size: 14, weight: FontWeight.w700, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.sep, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, color: _T.lime, size: 13),
              const SizedBox(width: 5),
              Text('Back', style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gallery',
              style: _T.f(size: 30, weight: FontWeight.w800, color: _T.white,
                  letterSpacing: -0.8, height: 1.12)),
          const SizedBox(height: 6),
          Text(widget.event.title ?? '', style: _T.f(size: 14, color: _T.lbl3)),
        ],
      ),
    );
  }

  Widget _foldersList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _foldersRef.orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CupertinoActivityIndicator(color: _T.lime),
            )),
          );
        }
        if (snapshot.hasError) return SliverToBoxAdapter(child: _errorState());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return SliverToBoxAdapter(child: _emptyState());

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final data = docs[i].data();
                return _folderCard(
                  folderId:  docs[i].id,
                  name:      data['name'] as String? ?? 'Unnamed',
                  createdAt: data['createdAt'] as String? ?? '',
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _folderCard({
    required String folderId,
    required String name,
    required String createdAt,
  }) {
    DateTime? dt;
    try { dt = DateTime.parse(createdAt); } catch (_) {}
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FolderView(
          event: widget.event,
          folderId: folderId,
          folderName: name,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _T.lime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_rounded, color: _T.lime, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl1)),
                  if (dt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${months[dt.month - 1]} ${dt.day}, ${dt.year}',
                      style: _T.f(size: 12, color: _T.lbl3),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: _T.lbl4, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _T.lime.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _T.lime.withValues(alpha: 0.2), width: 0.8),
            ),
            child: const Icon(Icons.folder_open_rounded, color: _T.lime, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No folders yet',
              style: _T.f(size: 18, weight: FontWeight.w700, color: _T.lbl1)),
          const SizedBox(height: 8),
          Text('Tap "New Folder" to create your first album.',
              textAlign: TextAlign.center,
              style: _T.f(size: 13, color: _T.lbl3, height: 1.5)),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: _T.lbl4, size: 36),
          const SizedBox(height: 16),
          Text('Failed to load gallery', style: _T.f(size: 14, color: _T.lbl3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FolderView — media grid inside a folder
// ─────────────────────────────────────────────────────────────────────────────

class _FolderView extends StatefulWidget {
  final Event  event;
  final String folderId;
  final String folderName;
  const _FolderView({required this.event, required this.folderId, required this.folderName});

  @override
  State<_FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<_FolderView> {
  final _firestore = FirebaseFirestore.instance;
  final _storage   = FirebaseStorage.instance;
  final _auth      = FirebaseAuth.instance;
  final _picker    = ImagePicker();

  bool   _uploading       = false;
  bool   _cancelRequested = false;
  double _uploadProgress  = 0;
  int    _uploadIndex     = 0;
  int    _uploadTotal     = 0;
  UploadTask? _currentTask;

  CollectionReference<Map<String, dynamic>> get _mediaRef =>
      _firestore.collection(ecol).doc(widget.event.id)
          .collection(_foldersSub).doc(widget.folderId).collection(_mediaSub);

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    await _upload(files: files, type: 'image');
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _upload(files: [file], type: 'video');
  }

  Future<void> _upload({required List<XFile> files, required String type}) async {
    setState(() {
      _uploading       = true;
      _cancelRequested = false;
      _uploadProgress  = 0;
      _uploadIndex     = 0;
      _uploadTotal     = files.length;
    });

    int uploaded = 0;
    try {
      for (int i = 0; i < files.length; i++) {
        if (_cancelRequested) break;

        final file = files[i];
        final ts   = DateTime.now().millisecondsSinceEpoch;
        final path = 'gallery/${widget.event.id}/${widget.folderId}/${ts}_${file.name}';
        final ref  = _storage.ref().child(path);

        _currentTask = ref.putFile(File(file.path));
        _currentTask!.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0 && mounted) {
            setState(() {
              _uploadIndex    = i + 1;
              _uploadProgress = snap.bytesTransferred / snap.totalBytes;
            });
          }
        });

        await _currentTask!;
        if (_cancelRequested) break;

        final url = await ref.getDownloadURL();
        await _mediaRef.add({
          'url':         url,
          'storagePath': path,
          'type':        type,
          'uploadedAt':  DateTime.now().toIso8601String(),
          'uploadedBy':  _auth.currentUser?.uid ?? '',
        });
        uploaded++;
      }

      if (_cancelRequested) {
        showToast(isGood: false,
            msg: 'Upload cancelled${uploaded > 0 ? ' ($uploaded saved)' : ''}');
      } else {
        showToast(isGood: true,
            msg: type == 'video' ? 'Video uploaded' : 'Photos uploaded');
      }
    } catch (e) {
      if (!_cancelRequested) showToast(isGood: false, msg: 'Upload failed: $e');
    } finally {
      if (mounted) setState(() {
        _uploading       = false;
        _cancelRequested = false;
        _uploadProgress  = 0;
        _uploadIndex     = 0;
        _uploadTotal     = 0;
        _currentTask     = null;
      });
    }
  }

  void _cancelUpload() {
    _currentTask?.cancel();
    setState(() => _cancelRequested = true);
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(String docId, String storagePath) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.90, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => const _LiquidGlassDeleteDialog(),
    );

    if (confirmed != true) return;
    try {
      await Future.wait([
        _mediaRef.doc(docId).delete(),
        _storage.ref().child(storagePath).delete(),
      ]);
      showToast(isGood: true, msg: 'Item deleted');
    } catch (e) {
      showToast(isGood: false, msg: 'Delete failed: $e');
    }
  }

  // ── Upload options sheet ───────────────────────────────────────────────────

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _T.card2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _T.sep, width: 0.8),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _T.lbl4, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Add to "${widget.folderName}"',
                style: _T.f(size: 16, weight: FontWeight.w700, color: _T.lbl1)),
            const SizedBox(height: 20),
            _optionTile(
              icon: Icons.photo_library_rounded,
              label: 'Photos',
              subtitle: 'Select multiple images',
              color: const Color(0xFF5AC8FA),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            const SizedBox(height: 12),
            _optionTile(
              icon: Icons.videocam_rounded,
              label: 'Video',
              subtitle: 'Select a video file',
              color: const Color(0xFFFF9F0A),
              onTap: () { Navigator.pop(context); _pickVideo(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: _T.f(size: 15, weight: FontWeight.w600, color: _T.lbl1)),
                  Text(subtitle, style: _T.f(size: 12, color: _T.lbl3)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: _T.lbl4, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Stack(
          children: [
            const Positioned(top: -80, right: -80,
                child: _GusOrb(size: 320, color: _T.lime, opacity: 0.11)),
            const Positioned(bottom: -40, left: -80,
                child: _GusOrb(size: 260, color: _T.lime, opacity: 0.06)),

            CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: SafeArea(bottom: false, child: _topBar())),
                SliverToBoxAdapter(child: _header()),
                _mediaGrid(),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ),
              ],
            ),

            if (!_uploading)
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: GestureDetector(
                  onTap: _showUploadOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: _T.lime,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(
                        color: _T.lime.withValues(alpha: 0.35),
                        blurRadius: 18, offset: const Offset(0, 6),
                      )],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text('Add Media',
                            style: _T.f(size: 14, weight: FontWeight.w700, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ),

            if (_uploading)
              Positioned(
                left: 16, right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: _uploadProgressBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.sep, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, color: _T.lime, size: 13),
              const SizedBox(width: 5),
              Text('Back', style: _T.f(size: 13, weight: FontWeight.w500, color: _T.lbl1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: _T.lime, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.folderName,
                style: _T.f(size: 26, weight: FontWeight.w800, color: _T.white,
                    letterSpacing: -0.6, height: 1.12)),
          ),
        ],
      ),
    );
  }

  Widget _mediaGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _mediaRef.orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CupertinoActivityIndicator(color: _T.lime),
            )),
          );
        }
        if (snapshot.hasError) return SliverToBoxAdapter(child: _errorState());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return SliverToBoxAdapter(child: _emptyState());

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final data = docs[i].data();
                final type = data['type'] as String? ?? 'image';
                return _mediaTile(
                  docId:       docs[i].id,
                  url:         data['url'] as String? ?? '',
                  storagePath: data['storagePath'] as String? ?? '',
                  type:        type,
                );
              },
              childCount: docs.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _mediaTile({
    required String docId,
    required String url,
    required String storagePath,
    required String type,
  }) {
    return GestureDetector(
      onTap: () {
        if (type == 'video') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _VideoPlayerScreen(url: url)));
        } else {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _PhotoViewer(url: url)));
        }
      },
      onLongPress: () => _confirmDelete(docId, storagePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: type == 'video'
            ? _videoTile()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: _T.card2,
                  child: const Center(
                      child: CupertinoActivityIndicator(color: _T.lime, radius: 10)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: _T.card2,
                  child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: _T.lbl4, size: 24)),
                ),
              ),
      ),
    );
  }

  Widget _videoTile() {
    return Container(
      color: _T.card2,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          const Icon(Icons.videocam_rounded, color: _T.lbl4, size: 30),
          Positioned(
            bottom: 6, right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: _T.lime, size: 12),
                  const SizedBox(width: 2),
                  Text('VIDEO',
                      style: _T.f(size: 8, weight: FontWeight.w800,
                          color: _T.lime, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _T.card2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.sep, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uploading...',
                  style: _T.f(size: 13, weight: FontWeight.w600, color: _T.lbl1)),
              Row(
                children: [
                  Text('$_uploadIndex / $_uploadTotal',
                      style: _T.f(size: 12, color: _T.lbl3)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _cancelUpload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 0.7),
                      ),
                      child: Text('Cancel',
                          style: _T.f(size: 11, weight: FontWeight.w700, color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadTotal > 0
                  ? ((_uploadIndex - 1 + _uploadProgress) / _uploadTotal)
                  : 0,
              backgroundColor: _T.card3,
              valueColor: const AlwaysStoppedAnimation<Color>(_T.lime),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _T.lime.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _T.lime.withValues(alpha: 0.2), width: 0.8),
            ),
            child: const Icon(Icons.photo_library_outlined, color: _T.lime, size: 36),
          ),
          const SizedBox(height: 20),
          Text('This folder is empty',
              style: _T.f(size: 18, weight: FontWeight.w700, color: _T.lbl1)),
          const SizedBox(height: 8),
          Text('Tap "Add Media" to upload photos or videos.',
              textAlign: TextAlign.center,
              style: _T.f(size: 13, color: _T.lbl3, height: 1.5)),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: _T.lbl4, size: 36),
          const SizedBox(height: 16),
          Text('Failed to load media', style: _T.f(size: 14, color: _T.lbl3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VideoPlayerScreen — fullscreen chewie player
// ─────────────────────────────────────────────────────────────────────────────

class _VideoPlayerScreen extends StatefulWidget {
  final String url;
  const _VideoPlayerScreen({required this.url});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _videoCtrl;
  ChewieController? _chewieCtrl;
  bool   _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoCtrl.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _chewieCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text('Failed to load video',
                            style: _T.f(size: 14, color: _T.lbl3)),
                      ],
                    )
                  : !_initialized
                      ? const CupertinoActivityIndicator(color: _T.lime)
                      : Chewie(controller: _chewieCtrl!),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhotoViewer — fullscreen with pinch-to-zoom
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const CupertinoActivityIndicator(color: _T.lime),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined, color: _T.lbl4, size: 48),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CreateFolderDialog — liquid glass
// ─────────────────────────────────────────────────────────────────────────────

class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog();

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _T.lime.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _T.lime.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: const Icon(Icons.create_new_folder_rounded,
                          color: _T.lime, size: 26),
                    ),
                    const SizedBox(height: 18),
                    Text('New Folder',
                        style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: -0.3,
                        )),
                    const SizedBox(height: 6),
                    Text('Give your album a name',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        )),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12), width: 0.8),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'e.g. Pre-Wedding',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 0.5,
                        color: Colors.white.withValues(alpha: 0.12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.8),
                              ),
                              child: Center(
                                child: Text('Cancel',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _submit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: _T.lime,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text('Create',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    )),
                              ),
                            ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LiquidGlassDeleteDialog
// ─────────────────────────────────────────────────────────────────────────────

class _LiquidGlassDeleteDialog extends StatelessWidget {
  const _LiquidGlassDeleteDialog();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: const Icon(CupertinoIcons.trash,
                          color: Colors.red, size: 24),
                    ),
                    const SizedBox(height: 18),
                    Text('Delete Item',
                        style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: -0.3,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'This item will be permanently removed from the gallery.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 0.5,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.8),
                              ),
                              child: Center(
                                child: Text('Cancel',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.4),
                                    width: 0.8),
                              ),
                              child: Center(
                                child: Text('Delete',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: Colors.red,
                                    )),
                              ),
                            ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GusOrb
// ─────────────────────────────────────────────────────────────────────────────

class _GusOrb extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _GusOrb({required this.size, required this.color, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
