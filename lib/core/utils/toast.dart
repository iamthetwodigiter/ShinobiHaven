import 'package:flutter/material.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:toastification/toastification.dart';

class Toast {
  Toast({
    required BuildContext context,
    required String title,
    required String description,
    ToastificationType type = ToastificationType.error,
    Duration? duration = const Duration(seconds: 5),
    AlignmentGeometry alignment = Alignment.bottomCenter,
  }) {
    _showToastification(
      context: context,
      title: title,
      description: description,
      type: type,
      duration: duration,
      alignment: alignment,
    );
  }

  void _showToastification({
    required BuildContext context,
    required String title,
    required String description,
    ToastificationType type = ToastificationType.error,
    Duration? duration = const Duration(seconds: 5),
    AlignmentGeometry alignment = Alignment.bottomCenter,
  }) {
    toastification.dismissAll();
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: duration,
      title: Text(
        title,
        style: TextStyle(
          color: _getToastColor(type),
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(description),
      alignment: alignment,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      showIcon: false,
      primaryColor: _getToastColor(type),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 16,
          offset: Offset(0, 16),
          spreadRadius: 0,
        ),
      ],
      showProgressBar: true,
      closeOnClick: true,
      pauseOnHover: false,
      dragToClose: true,
      applyBlurEffect: false,
    );
  }

  Color _getToastColor(ToastificationType type) {
    switch (type) {
      case ToastificationType.success:
        return AppTheme.primaryGreen;
      case ToastificationType.error:
        return AppTheme.primaryRed;
      case ToastificationType.warning:
        return AppTheme.primaryAmber;
      case ToastificationType.info:
        return AppTheme.primaryBlue;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
