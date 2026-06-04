import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/license_service.dart';

class LicenseRegisterScreen extends StatefulWidget {
  const LicenseRegisterScreen({super.key});

  @override
  State<LicenseRegisterScreen> createState() => _LicenseRegisterScreenState();
}

class _LicenseRegisterScreenState extends State<LicenseRegisterScreen> {
  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;
  bool isLoading = false;
  bool isRegistered = false;
  String? licenseImagePath;

  @override
  void initState() {
    super.initState();
    loadLicenseStatus();
  }

  Future<void> loadLicenseStatus() async {
    final status = await LicenseService.getLicenseStatus();

    if (!mounted) return;

    if (status == null) {
      setState(() {
        isRegistered = false;
        licenseImagePath = null;
      });
      return;
    }

    setState(() {
      isRegistered = status['license_registered'] ?? false;
      licenseImagePath = status['license_image_path'];
    });
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    setState(() {
      selectedImage = image;
    });
  }

  Future<void> uploadLicenseImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운전면허증 이미지를 먼저 선택해주세요.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await LicenseService.registerLicenseImage(
      imageFile: selectedImage!,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운전면허증 등록에 실패했습니다. 다시 시도해주세요.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('운전면허증 이미지가 등록되었습니다.')),
    );

    setState(() {
      isRegistered = true;
    });

    await loadLicenseStatus();
  }

  Widget buildImagePreview() {
    if (selectedImage == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFBFDBFE),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 64,
                color: Color(0xFF2563EB),
              ),
              SizedBox(height: 12),
              Text(
                '운전면허증 이미지를 선택해주세요.',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          selectedImage!.path,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.file(
        File(selectedImage!.path),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = isRegistered ? '등록 완료' : '미등록';
    final statusColor = isRegistered ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('운전면허증 등록'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadLicenseStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF2563EB),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '운전면허증 등록 상태',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                '운전면허증 이미지',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '전동킥보드 대여 전 본인 인증을 위해 운전면허증 이미지를 등록해주세요.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              buildImagePreview(),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: isLoading ? null : pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('이미지 선택'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: isLoading ? null : uploadLicenseImage,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(isLoading ? '등록 중...' : '운전면허증 등록'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              if (isRegistered && licenseImagePath != null) ...[
                const SizedBox(height: 20),
                Text(
                  '저장 경로: $licenseImagePath',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}