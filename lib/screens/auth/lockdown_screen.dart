import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LockdownScreen extends StatelessWidget {
  final String message;
  final bool isMaintenance;

  const LockdownScreen({
    super.key, 
    required this.message, 
    this.isMaintenance = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.globalGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMaintenance ? Icons.build_circle_outlined : Icons.lock_outline, 
                size: 80, 
                color: AppColors.adminRed
              ),
              const SizedBox(height: 24),
              Text(
                isMaintenance ? 'System Maintenance' : 'Access Suspended',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textHintColor, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}