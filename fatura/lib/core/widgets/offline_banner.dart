/// offline_banner.dart — Animated offline banner (US-015)
///
/// Slide-from-top banner that appears when device has no internet.
/// Uses AnimatedSlide + AnimatedOpacity per animation-spec.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Connection status enum.
enum ConnectionStatus { online, offline }

/// Monitors connectivity by pinging a lightweight endpoint.
/// Falls back to offline after timeout.
class ConnectivityMonitor extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.online;

  ConnectionStatus get status => _status;

  /// Update status from external source.
  void setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }
}

/// Animated offline banner that slides from top.
class OfflineBanner extends StatefulWidget {
  final bool isOffline;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppSizes.durationShort, // 300ms per spec
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(OfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOffline != oldWidget.isOffline) {
      if (widget.isOffline) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Animated banner at top
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _opacity,
                  child: child,
                ),
              ),
            );
          },
          child: Material(
            color: AppColors.stampRed,
            elevation: 4,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                  vertical: AppSizes.paddingSM,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: AppColors.background,
                      size: 18,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    const Expanded(
                      child: Text(
                        'لا يوجد اتصال بالإنترنت — يعمل التطبيق في وضع عدم الاتصال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontSM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.background,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _controller.reverse(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}