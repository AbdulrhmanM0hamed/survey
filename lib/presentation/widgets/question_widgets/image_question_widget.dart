import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageQuestionWidget extends StatefulWidget {
  final String questionText;
  final bool isRequired;
  final String? initialValue; // base64 string
  final Function(String?) onChanged;

  const ImageQuestionWidget({
    super.key,
    required this.questionText,
    required this.isRequired,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<ImageQuestionWidget> createState() => _ImageQuestionWidgetState();
}

class _ImageQuestionWidgetState extends State<ImageQuestionWidget> {
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  /// Extract pure base64 string from data URI (removes "data:image/...;base64," prefix)
  String _extractBase64(String base64String) {
    if (base64String.startsWith('data:image')) {
      final commaIndex = base64String.indexOf(',');
      if (commaIndex != -1) {
        return base64String.substring(commaIndex + 1);
      }
    }
    return base64String;
  }

  @override
  void initState() {
    super.initState();
    _base64Image = widget.initialValue;
  }

  @override
  void didUpdateWidget(ImageQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && mounted) {
      setState(() {
        _base64Image = widget.initialValue;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Read image bytes
        final bytes = await image.readAsBytes();
        
        // Convert to base64
        final base64String = base64Encode(bytes);
        
        // Get MIME type from file extension
        String mimeType = 'image/jpeg'; // default
        final extension = image.path.toLowerCase().split('.').last;
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }
        
        // Add MIME type prefix to base64 string
        final base64WithPrefix = 'data:$mimeType;base64,$base64String';
        
        // Check if widget is still mounted before calling setState
        if (!mounted) return;
        
        setState(() {
          _base64Image = base64WithPrefix;
        });
        
        widget.onChanged(base64WithPrefix);
        
        ////print('✅ Image captured: ${bytes.length} bytes → ${base64String.length} base64 chars');
        ////print('📷 MIME type: $mimeType');
      }
    } catch (e) {
      ////print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'اختر مصدر الصورة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue, size: 32),
              title: const Text('كاميرا', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green, size: 32),
              title: const Text('المعرض', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage() {
    if (!mounted) return;
    
    setState(() {
      _base64Image = null;
    });
    widget.onChanged(null);
  }

  bool get _hasValue => _base64Image != null && _base64Image!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with indicator
            Row(
              children: [
                // Required indicator (red/green circle)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isRequired
                        ? (_hasValue ? Colors.green : Colors.red)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image preview or upload button
            if (_hasValue)
              _buildImagePreview()
            else
              _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        // Image preview
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(_extractBase64(_base64Image!)),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.refresh),
                label: const Text('تغيير الصورة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete),
                label: const Text('حذف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isRequired && !_hasValue 
                ? Colors.red.shade300 
                : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 64,
              color: widget.isRequired && !_hasValue 
                  ? Colors.red.shade300 
                  : Colors.blue.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'اضغط لإضافة صورة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'كاميرا أو معرض الصور',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
