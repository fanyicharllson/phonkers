import 'package:flutter/material.dart';
import 'package:phonkers/data/service/network_status_service.dart';

class LibraryLoadingState extends StatelessWidget {
  const LibraryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.3),
                    Colors.pink.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ),
            const Icon(Icons.favorite, color: Colors.purpleAccent, size: 24),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Loading your favorites...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gathering your phonk collection',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }
}

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.2),
                Colors.pink.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: const Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.purpleAccent,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No favorites yet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Start adding phonk tracks to your library\nby tapping the ♥ icon on audios you searched or trending phonks.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore, color: Colors.purpleAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Explore phonk tracks',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LibraryErrorState extends StatefulWidget {
  final String error;
  final VoidCallback onRetry;

  const LibraryErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  State<LibraryErrorState> createState() => _LibraryErrorStateState();
}

class _LibraryErrorStateState extends State<LibraryErrorState> {
  final NetworkStatusService _networkService = NetworkStatusService();
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // Check network status when widget loads
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    await _networkService.hasInternetConnection();
    if (mounted) {
      setState(() {});
    }
  }

  bool _isNetworkError() {
    // Check if the error is related to network issues
    final errorLower = widget.error.toLowerCase();
    return errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('internet') ||
        errorLower.contains('timeout') ||
        errorLower.contains('unreachable') ||
        _networkService.isOffline;
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    // Check internet connection first
    final hasInternet = await _networkService.hasInternetConnection();

    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please check your internet connection and try again',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _isRetrying = false;
        });
      }
      return;
    }

    // Add a small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
      widget.onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkError = _isNetworkError();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isNetworkError
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isNetworkError
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                color: isNetworkError ? Colors.orange : Colors.red,
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Error Title
            Text(
              isNetworkError ? 'Connection Problem' : 'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Error Message
            Text(
              isNetworkError
                  ? 'Please check your internet connection and try again.'
                  : 'Unable to load your favorites right now.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),

            if (!isNetworkError) ...[
              const SizedBox(height: 8),
              Text(
                widget.error,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 32),

            // Retry Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRetrying ? null : _handleRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNetworkError
                      ? Colors.orange
                      : Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isRetrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _isRetrying ? 'Retrying...' : 'Try Again',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Network Status Indicator
            if (isNetworkError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _networkService.isOnline
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _networkService.isOnline
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _networkService.isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: _networkService.isOnline
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _networkService.isOnline ? 'Connected' : 'No Connection',
                      style: TextStyle(
                        color: _networkService.isOnline
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
