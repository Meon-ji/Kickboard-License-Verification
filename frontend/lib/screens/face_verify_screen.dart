import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/rental_service.dart';

class FaceVerifyScreen extends StatefulWidget {
  const FaceVerifyScreen({super.key});

  @override
  State<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends State<FaceVerifyScreen> {
  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;
  bool isLoading = false;

  bool? rentalAllowed;
  String? resultMessage;
  String? failReason;

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
      rentalAllowed = null;
      resultMessage = null;
      failReason = null;
    });
  }

  Future<void> verifyFace() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('얼굴 이미지를 먼저 선택해주세요.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await RentalService.verifyFace(
      imageFile: selectedImage!,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('얼굴 인증 요청에 실패했습니다. 다시 시도해주세요.')),
      );
      return;
    }

    setState(() {
      rentalAllowed = result['rental_allowed'] ?? false;
      resultMessage = result['message'] ?? '인증 결과를 확인할 수 없습니다.';
      failReason = result['fail_reason'];
    });
  }

  Widget buildImagePreview() {
    if (selectedImage == null) {
      return Container(
        height: 240,
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
                Icons.face_retouching_natural,
                size: 68,
                color: Color(0xFF2563EB),
              ),
              SizedBox(height: 12),
              Text(
                '대여 인증에 사용할 얼굴 이미지를 선택해주세요.',
                textAlign: TextAlign.center,
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
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.file(
        File(selectedImage!.path),
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget buildResultBox() {
    if (rentalAllowed == null) {
      return const SizedBox.shrink();
    }

    final bool allowed = rentalAllowed!;
    final Color mainColor = allowed ? Colors.green : Colors.red;
    final IconData icon = allowed ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allowed ? const Color(0xFFEFFAF1) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: mainColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: mainColor,
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allowed ? '대여 가능' : '대여 불가능',
                  style: TextStyle(
                    color: mainColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resultMessage ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (failReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '실패 사유: $failReason',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대여 시 얼굴 인증'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '얼굴 인증',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '전동킥보드 대여 전 현재 얼굴 사진을 등록된 운전면허증 이미지와 비교합니다.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              buildImagePreview(),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: isLoading ? null : pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('얼굴 이미지 선택'),
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
                onPressed: isLoading ? null : verifyFace,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(isLoading ? '인증 중...' : '얼굴 인증 요청'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              buildResultBox(),
            ],
          ),
        ),
      ),
    );
  }
}