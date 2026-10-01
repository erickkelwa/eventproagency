import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../events/models/event_model.dart';
import '../providers/admin_provider.dart';

const _categories = [
  'Music', 'Conference', 'Sports', 'Comedy', 'Art', 'Food', 'Tech', 'Other',
];

class CreateEditEventScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const CreateEditEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEditEventScreen> createState() =>
      _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends ConsumerState<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  String _selectedCategory = _categories.first;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isFeatured = false;
  File? _selectedImage;
  bool _isLoading = false;
  EventModel? _existingEvent;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final response = await DioClient.instance.dio.get(
        ApiConstants.eventDetail.replaceAll('{id}', widget.eventId!),
      );
      final event = EventModel.fromJson(response.data['event']);
      setState(() {
        _existingEvent = event;
        _titleCtrl.text = event.title;
        _descCtrl.text = event.description;
        _venueCtrl.text = event.venue;
        _addressCtrl.text = event.address ?? '';
        _priceCtrl.text = event.price.toStringAsFixed(0);
        _capacityCtrl.text = event.capacity.toString();
        _selectedCategory = event.category;
        _selectedDate = event.date;
        _selectedTime = TimeOfDay.fromDateTime(event.date);
        _isFeatured = event.isFeatured;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final formData = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'venue': _venueCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'date': eventDateTime.toIso8601String(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'capacity': int.tryParse(_capacityCtrl.text) ?? 100,
        'is_featured': _isFeatured ? 1 : 0,
      };

      if (_isEditing) {
        await DioClient.instance.dio.put(
          '${ApiConstants.adminEvents}/${widget.eventId}',
          data: formData,
        );
      } else {
        await DioClient.instance.dio.post(
          ApiConstants.adminEventCreate,
          data: formData,
        );
      }

      // Upload image if selected
      if (_selectedImage != null) {
        // Image upload handled separately
      }

      if (mounted) {
        ref.read(adminEventsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Event updated successfully!'
                : 'Event created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Event' : 'Create Event',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _GradientButton(
                label: _isEditing ? 'Update' : 'Publish',
                onTap: _submit,
              ),
            ),
        ],
      ),
      body: _isLoading && _isEditing && _existingEvent == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Image Picker ─────────────────────────────
                  _ImagePicker(
                    image: _selectedImage,
                    existingUrl: _existingEvent?.imageUrl,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 24),

                  // ── Title ─────────────────────────────────────
                  _SectionLabel('Event Title'),
                  _EventField(
                    controller: _titleCtrl,
                    hint: 'e.g. Nairobi Music Festival 2026',
                    validator: (v) =>
                        v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────
                  _SectionLabel('Description'),
                  _EventField(
                    controller: _descCtrl,
                    hint: 'Describe the event...',
                    maxLines: 4,
                    validator: (v) =>
                        v!.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Category ───────────────────────────────────
                  _SectionLabel('Category'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: AppColors.card,
                        style: TextStyle(color: AppColors.textPrimary),
                        isExpanded: true,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Date & Time ─────────────────────────────────
                  _SectionLabel('Date & Time'),
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

                  // ── Venue ──────────────────────────────────────
                  _SectionLabel('Venue Name'),
                  _EventField(
                    controller: _venueCtrl,
                    hint: 'e.g. KICC, Nairobi',
                    validator: (v) => v!.isEmpty ? 'Venue is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel('Address (optional)'),
                  _EventField(
                    controller: _addressCtrl,
                    hint: 'Full address or Google Maps link',
                  ),
                  const SizedBox(height: 20),

                  // ── Price & Capacity ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Ticket Price (KES)'),
                            _EventField(
                              controller: _priceCtrl,
                              hint: '0 = Free',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Capacity'),
                            _EventField(
                              controller: _capacityCtrl,
                              hint: 'e.g. 500',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (int.tryParse(v) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Featured Toggle ────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.star_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Featured Event',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Show on home banner',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isFeatured,
                          onChanged: (v) => setState(() => _isFeatured = v),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Submit Button ──────────────────────────────
                  SizedBox(
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isEditing
                                    ? 'Update Event'
                                    : 'Publish Event',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EventField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _EventField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
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

  const _DateTimeTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final File? image;
  final String? existingUrl;
  final VoidCallback onTap;

  const _ImagePicker(
      {required this.image, this.existingUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            style: image == null && existingUrl == null
                ? BorderStyle.solid
                : BorderStyle.none,
          ),
          image: image != null
              ? DecorationImage(
                  image: FileImage(image!),
                  fit: BoxFit.cover,
                )
              : existingUrl != null
                  ? DecorationImage(
                      image: NetworkImage(existingUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: image == null && existingUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to add event image',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Change',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}