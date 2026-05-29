import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../providers/analysis_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class EEGUploadScreen extends ConsumerStatefulWidget {
  const EEGUploadScreen({super.key});

  @override
  ConsumerState<EEGUploadScreen> createState() => _EEGUploadScreenState();
}

class _EEGUploadScreenState extends ConsumerState<EEGUploadScreen> {
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['edf', 'csv'],
      withData: true, // Importante para web
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        _fileBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un archivo primero')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.uploadEEGBytes(_fileBytes!, _selectedFile!.name);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Análisis completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Navegar directamente al detalle del análisis recién creado
        final analysisId = response['id'] as int;
        Navigator.pushReplacementNamed(
          context,
          '/analysis-detail',
          arguments: analysisId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Archivo EEG')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 100,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            Text(
              'Seleccione un archivo EEG',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Formatos soportados: EDF, CSV',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_selectedFile != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(_selectedFile!.name),
                  subtitle: Text(
                    '${(_fileBytes!.length / 1024).toStringAsFixed(2)} KB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _fileBytes = null;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Seleccionar Archivo'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading || _selectedFile == null
                    ? null
                    : _uploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Procesando...' : 'Subir y Analizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
