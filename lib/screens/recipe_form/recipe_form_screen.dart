import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_book/screens/home/home_screen.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/app_theme.dart';
import '../../data/ingredients_data.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';

class RecipeFormScreen extends StatefulWidget {
  /// null ise yeni tarif ekleme, dolu ise düzenleme
  final String? recipeId;

  const RecipeFormScreen({super.key, this.recipeId});

  bool get isEditing => recipeId != null;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Recipe _form;
  File? _pickedImage;
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final auth = context.read<AuthProvider>();
      if (widget.isEditing) {
        final existing =
            context.read<RecipeProvider>().getById(widget.recipeId!);
        if (existing == null ||
            existing.isSeeded ||
            (existing.userId.isNotEmpty && existing.userId != auth.userId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppSnackbar.show(
                context,
                'Yalnızca kendi eklediğiniz tarifleri düzenleyebilirsiniz.',
                isError: true,
              );
              Navigator.of(context).pop();
            }
          });
          _form = Recipe.empty();
          return;
        }
        _form = existing;
      } else {
        _form = Recipe.empty().copyWith(
          userId: auth.userId,
          authorName: auth.displayName,
        );
      }
    }
  }

  void _showIngredientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _IngredientSearchSheet(
        alreadySelected: _form.ingredients,
        onToggle: (ingredient) {
          final list = List<String>.from(_form.ingredients);
          if (list.contains(ingredient)) {
            list.remove(ingredient);
          } else {
            list.add(ingredient);
          }
          setState(() => _form = _form.copyWith(ingredients: list));
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    final list = List<String>.from(_form.ingredients)..removeAt(index);
    setState(() => _form = _form.copyWith(ingredients: list));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_form.ingredients.isEmpty) {
      AppSnackbar.show(context, 'En az bir malzeme ekleyin.', isError: true);
      return;
    }

    setState(() => _loading = true);
    final provider = context.read<RecipeProvider>();
    final auth = context.read<AuthProvider>();

    try {
      String imageUrl = _form.image;

      // Yeni resim seçildi mi?
      if (_pickedImage != null) {
        final uploaded = await provider.uploadImage(_pickedImage!);
        imageUrl = uploaded ?? _form.image;
      }

      final finalRecipe = _form.copyWith(
        image: imageUrl,
        userId: _form.userId.isNotEmpty ? _form.userId : auth.userId,
        authorName: _form.authorName.isNotEmpty ? _form.authorName : auth.displayName,
      );

      if (widget.isEditing) {
        await provider.updateRecipe(finalRecipe);
        if (mounted) AppSnackbar.show(context, 'Tarif güncellendi ✅');
      } else {
        await provider.addRecipe(finalRecipe);
        if (mounted) AppSnackbar.show(context, 'Tarif eklendi 🎉');
      }

      if (mounted) {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          nav.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
      
    } catch (e, st) {
      debugPrint('Kaydetme hatası: $e\n$st');
      if (mounted) {
        AppSnackbar.show(context, 'Bir hata oluştu.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDelete() async {
  final confirmed = await ConfirmDialog.show(
    context,
    title: 'Emin misin?',
    message: 'İlerlemen silinecek ve baştan başlayacaksın.',
    confirmLabel: 'Sil',
  );
  if (!confirmed || !mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  final provider = context.read<RecipeProvider>();

  if (widget.isEditing) {
    try {
      await provider.deleteRecipe(widget.recipeId!);
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      if (mounted) AppSnackbar.show(context, 'Tarif silindi 🗑️');
    } catch (e, st) {
      debugPrint('Silme hatası: $e\n$st');
      if (mounted) {
        AppSnackbar.show(context, 'Silme sırasında hata oluştu.', isError: true);
      }
    }
  } else {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Tarifi Düzenle' : 'Yeni Tarif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Kapat',
            onPressed: _loading ? null : _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              _ImagePicker(
                existingUrl: _form.image,
                pickedFile: _pickedImage,
                onPickCamera: () => _pickImage(ImageSource.camera),
                onPickGallery: () => _pickImage(ImageSource.gallery),
                onRemove: () =>
                    setState(() {
                      _pickedImage = null;
                      _form = _form.copyWith(image: '');
                    }),
              ),
              const SizedBox(height: 20),
              // Name
              TextFormField(
                initialValue: _form.name,
                decoration: const InputDecoration(labelText: 'Tarif Adı *'),
                onChanged: (v) => _form = _form.copyWith(name: v),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Tarif adı zorunludur.'
                    : null,
              ),
              const SizedBox(height: 16),
              // Category + Difficulty row
              Row(
                children: [
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Kategori',
                      value: _form.category,
                      items: kCategories,
                      onChanged: (v) =>
                          setState(() => _form = _form.copyWith(category: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Zorluk',
                      value: _form.difficulty,
                      items: kDifficulties,
                      onChanged: (v) =>
                          setState(() => _form = _form.copyWith(difficulty: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Duration + Servings row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _form.duration.toString(),
                      decoration:
                          const InputDecoration(labelText: 'Süre (dakika) *'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _form = _form.copyWith(duration: int.tryParse(v) ?? 0),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Geçerli bir süre girin.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _form.servings.toString(),
                      decoration:
                          const InputDecoration(labelText: 'Porsiyon'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _form = _form.copyWith(servings: int.tryParse(v) ?? 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Malzeme Ekle'),
                  onPressed: _showIngredientPicker,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _form.ingredients.length,
                  (i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _form.ingredients[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 31, 58, 36),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeIngredient(i),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Instructions
              TextFormField(
                initialValue: _form.instructions,
                decoration: const InputDecoration(
                  labelText: 'Hazırlanışı *',
                  alignLabelWithHint: true, // etiket kutunun üstünde başlar
                ),
                minLines: 3,
                maxLines: 4, // daha kısa, fazlası kaydırılır
                keyboardType: TextInputType.multiline,
                onChanged: (v) => _form = _form.copyWith(instructions: v),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Yapılış adımları zorunludur.'
                    : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.paprika,
                        ),
                        label: const Text(
                          'Tarifi Sil',
                          style: TextStyle(color: AppColors.paprika),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.paprika, width: 1.5),
                        ),
                        onPressed: _loading ? null : _handleDelete,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : Text(widget.isEditing
                                ? 'Güncelle'
                                : 'Tarifi Kaydet'),
                      ),
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Sub-widgets ----

class _ImagePicker extends StatelessWidget {
  final String existingUrl;
  final File? pickedFile;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  const _ImagePicker({
    required this.existingUrl,
    required this.pickedFile,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  bool get hasImage => pickedFile != null || existingUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.sage.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  pickedFile != null
                      ? Image.file(pickedFile!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: existingUrl, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(130),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      size: 40, color: AppColors.brand),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraf Ekle',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Kamera veya galeri',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8A8478),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                onPickCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                onPickGallery();
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.paprika),
                title: const Text('Fotoğrafı Kaldır',
                    style: TextStyle(color: AppColors.paprika)),
                onTap: () {
                  Navigator.pop(context);
                  onRemove();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((i) => DropdownMenuItem<T>(
                value: i,
                child: Text(i.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _IngredientSearchSheet extends StatefulWidget {
  final List<String> alreadySelected;
  final ValueChanged<String> onToggle;

  const _IngredientSearchSheet({
    required this.alreadySelected,
    required this.onToggle,
  });

  @override
  State<_IngredientSearchSheet> createState() => _IngredientSearchSheetState();
}

class _IngredientSearchSheetState extends State<_IngredientSearchSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.alreadySelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return kAllIngredients;
    return kAllIngredients
        .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Malzeme Ara',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Malzeme adı yazın... (ör: biber)',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '"$_query" ile eşleşen malzeme bulunamadı.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8A8478),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, i) {
                      final ingredient = filtered[i];
                      final isAlready = _selected.contains(ingredient);
                      return ListTile(
                        dense: true,
                        title: Text(
                          ingredient,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAlready
                                ? const Color(0xFF8A8478)
                                : AppColors.ink,
                          ),
                        ),
                        trailing: isAlready
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.brand,
                                size: 20,
                              )
                            : const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.brand,
                                size: 20,
                              ),
                        onTap: () {
                          widget.onToggle(ingredient); // forma ekler ya da çıkarır
                          setState(() {
                            if (_selected.contains(ingredient)) {
                              _selected.remove(ingredient);
                            } else {
                              _selected.add(ingredient);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
