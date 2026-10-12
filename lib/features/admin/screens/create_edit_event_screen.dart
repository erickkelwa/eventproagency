import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/models/event_model.dart';
import '../../events/providers/events_provider.dart';
import '../providers/admin_provider.dart';

const _categories = [
  'Music',
  'Conference',
  'Sports',
  'Comedy',
  'Art',
  'Food',
  'Tech',
  'Other',
];

// ─────────────────────────────────────────────────────────────────────────────
// Ticket Tier Model
// ─────────────────────────────────────────────────────────────────────────────
class TicketTier {
  String name;
  double price;
  int capacity;
  String perks;

  TicketTier({
    required this.name,
    required this.price,
    required this.capacity,
    this.perks = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'capacity': capacity,
        'perks': perks,
      };

  factory TicketTier.fromJson(Map<String, dynamic> j) => TicketTier(
        name: j['name'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        capacity: j['capacity'] as int? ?? 0,
        perks: j['perks'] as String? ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CreateEditEventScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const CreateEditEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEditEventScreen> createState() =>
      _CreateEditEventScreenState();
}

class _CreateEditEventScreenState
    extends ConsumerState<CreateEditEventScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  // ── Text Controllers ──────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _guestCtrl = TextEditingController();
  final _highlightCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────
  String _selectedCategory = _categories.first;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isFeatured = false;
  bool _isFree = false;
  bool _isLoading = false;
  bool _isLoadingEvent = false;
  XFile? _pickedImageFile;

  List<String> _guests = [];
  List<String> _highlights = [];
  List<TicketTier> _tiers = [];

  bool get _isEditing => widget.eventId != null;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (_isEditing) _loadEvent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _titleCtrl, _descCtrl, _venueCtrl, _addressCtrl, _priceCtrl,
      _capacityCtrl, _latCtrl, _lngCtrl, _imageUrlCtrl, _organizerCtrl,
      _guestCtrl, _highlightCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load existing event from Firestore ────────────────────
  Future<void> _loadEvent() async {
    setState(() => _isLoadingEvent = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();
      if (doc.exists) {
        final data = doc.data()!..['id'] = doc.id;
        final event = EventModel.fromJson(data);
        _populateFromEvent(event);
        // Load tiers if present
        final tiersList = data['tiers'] as List? ?? [];
        _tiers = tiersList
            .map((t) => TicketTier.fromJson(t as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Try from curated events
      try {
        final curated = EventsNotifier.getCuratedEvents();
        final match = curated.where((e) => e.id == widget.eventId).firstOrNull;
        if (match != null) _populateFromEvent(match);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoadingEvent = false);
    }
  }

  void _populateFromEvent(EventModel e) {
    _titleCtrl.text = e.title;
    _descCtrl.text = e.description;
    _venueCtrl.text = e.venue;
    _addressCtrl.text = e.address ?? '';
    _priceCtrl.text = e.price.toStringAsFixed(0);
    _capacityCtrl.text = e.capacity.toString();
    _latCtrl.text = e.latitude?.toString() ?? '';
    _lngCtrl.text = e.longitude?.toString() ?? '';
    _organizerCtrl.text = e.organizerName ?? '';
    _selectedCategory = _categories.contains(e.category)
        ? e.category
        : _categories.first;
    _selectedDate = e.date;
    _selectedTime = TimeOfDay.fromDateTime(e.date);
    _isFeatured = e.isFeatured;
    _isFree = e.isFree;
    _guests = List<String>.from(e.guests);
    _highlights = List<String>.from(e.highlights);
    _existingImageUrl = e.imageUrl;
  }

  // ── Image Picking ─────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (picked != null) setState(() => _pickedImageFile = picked);
  }

  // ── Upload image to Firebase Storage ─────────────────────
  Future<String?> _uploadImage(String eventId) async {
    if (_pickedImageFile == null) return _existingImageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('event_images/$eventId.jpg');
      UploadTask task;
      if (kIsWeb) {
        final bytes = await _pickedImageFile!.readAsBytes();
        task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putFile(File(_pickedImageFile!.path));
      }
      final snap = await task;
      return await snap.ref.getDownloadURL();
    } catch (_) {
      return _imageUrlCtrl.text.isNotEmpty ? _imageUrlCtrl.text : _existingImageUrl;
    }
  }

  // ── Date / Time Pickers ───────────────────────────────────
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: _darkPickerTheme,
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: _darkPickerTheme,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Widget Function(BuildContext, Widget?) get _darkPickerTheme =>
      (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.card,
              ),
            ),
            child: child!,
          );

  // ── Guest helpers ─────────────────────────────────────────
  void _addGuest() {
    final v = _guestCtrl.text.trim();
    if (v.isEmpty || _guests.contains(v)) return;
    setState(() {
      _guests.add(v);
      _guestCtrl.clear();
    });
  }

  void _removeGuest(int i) => setState(() => _guests.removeAt(i));

  // ── Highlight helpers ─────────────────────────────────────
  void _addHighlight() {
    final v = _highlightCtrl.text.trim();
    if (v.isEmpty || _highlights.contains(v)) return;
    setState(() {
      _highlights.add(v);
      _highlightCtrl.clear();
    });
  }

  void _removeHighlight(int i) => setState(() => _highlights.removeAt(i));

  // ── Tier helpers ──────────────────────────────────────────
  void _addTier() {
    setState(() => _tiers.add(TicketTier(
          name: 'Regular',
          price: double.tryParse(_priceCtrl.text) ?? 0,
          capacity: int.tryParse(_capacityCtrl.text) ?? 100,
        )));
  }

  void _removeTier(int i) => setState(() => _tiers.removeAt(i));

  // ── Validate basic tab ────────────────────────────────────
  bool _validateBasics() {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_descCtrl.text.trim().isEmpty) return false;
    if (_venueCtrl.text.trim().isEmpty) return false;
    if (!_isFree && (double.tryParse(_priceCtrl.text) == null)) return false;
    if (int.tryParse(_capacityCtrl.text) == null) return false;
    return true;
  }

  // ── Save to Firestore ─────────────────────────────────────
  Future<void> _submit() async {
    if (!_validateBasics()) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields in the Basic Info tab'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final firestore = FirebaseFirestore.instance;
      final id = _isEditing
          ? widget.eventId!
          : const Uuid().v4();

      // Upload image first
      final imageUrl = await _uploadImage(id);

      final data = <String, dynamic>{
        'id': id,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'venue': _venueCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'date': eventDateTime.toIso8601String(),
        'price': _isFree ? 0.0 : (double.tryParse(_priceCtrl.text) ?? 0.0),
        'capacity': int.tryParse(_capacityCtrl.text) ?? 100,
        'booked_count': 0,
        'image_url': imageUrl,
        'latitude': double.tryParse(_latCtrl.text),
        'longitude': double.tryParse(_lngCtrl.text),
        'organizer_id': id,
        'organizer_name': _organizerCtrl.text.trim().isEmpty
            ? 'EventPro Admin'
            : _organizerCtrl.text.trim(),
        'is_featured': _isFeatured,
        'guests': _guests,
        'highlights': _highlights,
        'tiers': _tiers.map((t) => t.toJson()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        await firestore.collection('events').doc(id).update(data);
      } else {
        data['created_at'] = FieldValue.serverTimestamp();
        await firestore.collection('events').doc(id).set(data);
      }

      // Also try to sync to Laravel API (non-blocking)
      _syncToApi(data).ignore();

      if (mounted) {
        ref.invalidate(eventsProvider);
        ref.invalidate(adminEventsProvider);
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncToApi(Map<String, dynamic> data) async {
    try {
      // Sync to Laravel backend in background — silently ignore errors
      // DioClient.instance.dio.post('/admin/events', data: data);
    } catch (_) {}
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing
                    ? 'Event Updated!'
                    : 'Event Published!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? 'Changes have been saved to Firestore.'
                    : 'Your event is now live and visible to users.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingEvent) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicsTab(),
                  _buildMediaTab(),
                  _buildGuestsTab(),
                  _buildTicketsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Event' : 'Create Event',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            _isEditing ? 'Updating Firestore' : 'Publishing to Firestore',
            style:
                TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _isEditing ? 'Update' : 'Publish',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Basics'),
          Tab(icon: Icon(Icons.image_outlined, size: 18), text: 'Media'),
          Tab(icon: Icon(Icons.people_outline_rounded, size: 18), text: 'Guests'),
          Tab(icon: Icon(Icons.confirmation_number_outlined, size: 18), text: 'Tickets'),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SizedBox(
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient:
                _isLoading ? null : AppColors.primaryGradient,
            color: _isLoading ? AppColors.border : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_rounded,
                    color: Colors.white, size: 20),
            label: Text(
              _isLoading
                  ? 'Saving…'
                  : (_isEditing ? 'Update Event' : 'Publish Event'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Tab 1 — Basics
  // ─────────────────────────────────────────────────────────
  Widget _buildBasicsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title
        _Label('Event Title *'),
        _Field(
          controller: _titleCtrl,
          hint: 'e.g. Nairobi Music Festival 2026',
          validator: (v) => v!.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 20),

        // Description
        _Label('Description *'),
        _Field(
          controller: _descCtrl,
          hint:
              'Describe the event experience, what to expect, highlights…',
          maxLines: 5,
          validator: (v) =>
              v!.trim().isEmpty ? 'Description is required' : null,
        ),
        const SizedBox(height: 20),

        // Category
        _Label('Category'),
        _CategoryPicker(
          selected: _selectedCategory,
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
        const SizedBox(height: 20),

        // Date & Time
        _Label('Date & Time *'),
        Row(
          children: [
            Expanded(
              child: _DateTimeTile(
                icon: Icons.calendar_today_rounded,
                label: DateFormat('EEE, MMM d, y').format(_selectedDate),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateTimeTile(
                icon: Icons.access_time_rounded,
                label: _selectedTime.format(context),
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Venue
        _Label('Venue Name *'),
        _Field(
          controller: _venueCtrl,
          hint: 'e.g. KICC, Nairobi',
          prefixIcon: Icons.location_on_rounded,
          validator: (v) =>
              v!.trim().isEmpty ? 'Venue is required' : null,
        ),
        const SizedBox(height: 16),

        _Label('Address (Street / Area)'),
        _Field(
          controller: _addressCtrl,
          hint: 'Full street address or landmark',
          prefixIcon: Icons.place_outlined,
        ),
        const SizedBox(height: 20),

        // Lat/Lng
        _Label('GPS Coordinates (optional)'),
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: _latCtrl,
                hint: 'Latitude  e.g. -1.286',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                controller: _lngCtrl,
                hint: 'Longitude  e.g. 36.817',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Enter coordinates to show Google Maps & directions in the event detail.',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Organizer
        _Label('Organizer Name'),
        _Field(
          controller: _organizerCtrl,
          hint: 'e.g. EventPro Productions',
          prefixIcon: Icons.business_rounded,
        ),
        const SizedBox(height: 20),

        // Capacity
        _Label('Total Capacity *'),
        _Field(
          controller: _capacityCtrl,
          hint: 'e.g. 500',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.people_rounded,
          validator: (v) {
            if (v!.trim().isEmpty) return 'Required';
            if (int.tryParse(v) == null) return 'Enter a valid number';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Featured toggle
        _ToggleTile(
          icon: Icons.star_rounded,
          title: 'Featured Event',
          subtitle: 'Appears prominently on home hero banners',
          value: _isFeatured,
          gradient: AppColors.primaryGradient,
          onChanged: (v) => setState(() => _isFeatured = v),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Tab 2 — Media
  // ─────────────────────────────────────────────────────────
  Widget _buildMediaTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Event Cover Image',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a high-quality image (min 1200×600px recommended).',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Image preview / picker
        GestureDetector(
          onTap: _pickImage,
          child: _ImagePreview(
            pickedFile: _pickedImageFile,
            existingUrl: _existingImageUrl,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: Text(
              _pickedImageFile != null || _existingImageUrl != null
                  ? 'Change Image'
                  : 'Upload from Gallery',
            ),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary),
          ),
        ),
        const SizedBox(height: 24),

        const _Divider(label: 'or paste an image URL'),
        const SizedBox(height: 16),

        _Label('Image URL (optional)'),
        _Field(
          controller: _imageUrlCtrl,
          hint: 'https://example.com/image.jpg',
          prefixIcon: Icons.link_rounded,
        ),
        const SizedBox(height: 8),
        Text(
          'If provided and no file is uploaded, this URL will be used as the cover.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Tab 3 — Guests & Highlights
  // ─────────────────────────────────────────────────────────
  Widget _buildGuestsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Guests ──────────────────────────────────────────
        Text(
          'Featured Guests & Performers',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Add artists, speakers, or special guests who will appear.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: _guestCtrl,
                hint: 'e.g. Sauti Sol',
                prefixIcon: Icons.mic_rounded,
                onSubmitted: (_) => _addGuest(),
              ),
            ),
            const SizedBox(width: 10),
            _AddButton(onTap: _addGuest),
          ],
        ),
        const SizedBox(height: 14),
        if (_guests.isEmpty)
          _EmptyChip(label: 'No guests added yet')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _guests.asMap().entries.map((e) {
              return _GuestChip(
                name: e.value,
                onRemove: () => _removeGuest(e.key),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),

        // ── Highlights ──────────────────────────────────────
        Text(
          'Event Highlights & Perks',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'List key benefits attendees will enjoy.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: _highlightCtrl,
                hint: 'e.g. Free VIP Backstage Access',
                prefixIcon: Icons.check_circle_outline_rounded,
                onSubmitted: (_) => _addHighlight(),
              ),
            ),
            const SizedBox(width: 10),
            _AddButton(onTap: _addHighlight),
          ],
        ),
        const SizedBox(height: 14),
        if (_highlights.isEmpty)
          _EmptyChip(label: 'No highlights added yet')
        else
          Column(
            children: _highlights.asMap().entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 13, color: AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600))),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textMuted),
                      onPressed: () => _removeHighlight(e.key),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Tab 4 — Tickets / Price Tiers
  // ─────────────────────────────────────────────────────────
  Widget _buildTicketsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Free event toggle
        _ToggleTile(
          icon: Icons.card_giftcard_rounded,
          title: 'Free Event',
          subtitle: 'No ticket price — open to all',
          value: _isFree,
          gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)]),
          onChanged: (v) => setState(() => _isFree = v),
        ),
        const SizedBox(height: 20),

        if (!_isFree) ...[
          // Default price
          _Label('Default Ticket Price (KES) *'),
          _Field(
            controller: _priceCtrl,
            hint: '0 = Free',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money_rounded,
            validator: (v) {
              if (_isFree) return null;
              if (v!.isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid amount';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Ticket Tiers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket Tiers',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              TextButton.icon(
                onPressed: _addTier,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Tier'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary),
              ),
            ],
          ),
          Text(
            'Create multiple ticket categories (e.g. VIP, Regular, Early Bird).',
            style:
                TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (_tiers.isEmpty)
            _EmptyChip(
                label:
                    'No tiers yet — using single default price above')
          else
            Column(
              children: _tiers.asMap().entries.map((e) {
                return _TierCard(
                  tier: e.value,
                  index: e.key,
                  onRemove: () => _removeTier(e.key),
                  onChanged: () => setState(() {}),
                );
              }).toList(),
            ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final void Function(String)? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textMuted, size: 18)
            : null,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _CategoryPicker(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: AppColors.card,
          style: TextStyle(
              color: AppColors.textPrimary, fontSize: 14),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted),
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(_categoryIcon(c),
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(c),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Music':
        return Icons.music_note_rounded;
      case 'Conference':
        return Icons.groups_rounded;
      case 'Sports':
        return Icons.sports_rounded;
      case 'Comedy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Art':
        return Icons.palette_rounded;
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Tech':
        return Icons.computer_rounded;
      default:
        return Icons.event_rounded;
    }
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final LinearGradient gradient;
  final void Function(bool) onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final XFile? pickedFile;
  final String? existingUrl;

  const _ImagePreview({this.pickedFile, this.existingUrl});

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (pickedFile != null) {
      if (kIsWeb) {
        child = Image.network(
          pickedFile!.path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderChild(),
        );
      } else {
        child = Image.file(File(pickedFile!.path), fit: BoxFit.cover);
      }
    } else if (existingUrl != null && existingUrl!.isNotEmpty) {
      child = Image.network(existingUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderChild());
    } else {
      child = _placeholderChild();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Container(
          color: AppColors.card,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (pickedFile == null && existingUrl == null)
                const SizedBox.shrink()
              else
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Change',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderChild() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_rounded,
              color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          'Tap to add event image',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG — min 1200 × 600 px',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: 22),
      ),
    );
  }
}

class _GuestChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _GuestChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Text(name,
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _EmptyChip extends StatelessWidget {
  final String label;
  const _EmptyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticket Tier Card (editable)
// ─────────────────────────────────────────────────────────────────────────────
class _TierCard extends StatefulWidget {
  final TicketTier tier;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _TierCard({
    required this.tier,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _capCtrl;
  late TextEditingController _perksCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.tier.name);
    _priceCtrl = TextEditingController(
        text: widget.tier.price.toStringAsFixed(0));
    _capCtrl =
        TextEditingController(text: widget.tier.capacity.toString());
    _perksCtrl = TextEditingController(text: widget.tier.perks);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    _perksCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.tier.name = _nameCtrl.text;
    widget.tier.price = double.tryParse(_priceCtrl.text) ?? 0;
    widget.tier.capacity = int.tryParse(_capCtrl.text) ?? 0;
    widget.tier.perks = _perksCtrl.text;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final tierColors = [
      AppColors.primaryGradient,
      const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)]),
    ];
    final gradient =
        tierColors[widget.index % tierColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tier ${widget.index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.error),
                onPressed: widget.onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _MiniField(
                  ctrl: _nameCtrl,
                  label: 'Tier Name',
                  hint: 'e.g. VIP',
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniField(
                  ctrl: _priceCtrl,
                  label: 'Price (KES)',
                  hint: '5000',
                  type: TextInputType.number,
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniField(
                  ctrl: _capCtrl,
                  label: 'Slots',
                  hint: '50',
                  type: TextInputType.number,
                  onChanged: (_) => _sync(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MiniField(
            ctrl: _perksCtrl,
            label: 'Perks / Benefits',
            hint:
                'e.g. Meet & Greet, Front Row, Complimentary Drinks',
            onChanged: (_) => _sync(),
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType type;
  final void Function(String)? onChanged;

  const _MiniField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.type = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          onChanged: onChanged,
          style:
              TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}