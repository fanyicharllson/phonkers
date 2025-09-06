import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/data/service/post_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';

class PostMoreOptions extends StatefulWidget {
  final String postId;
  final String postOwnerId;

  const PostMoreOptions({
    super.key,
    required this.postId,
    required this.postOwnerId,
  });

  @override
  State<PostMoreOptions> createState() => _PostMoreOptionsState();
}

class _PostMoreOptionsState extends State<PostMoreOptions>
    with NetworkAwareMixin {
  String? currentUserId;
  bool _isDeleting = false;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: _isDeleting || _isReporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white60),
              ),
            )
          : IconButton(
              onPressed: () async {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final Offset position = button.localToGlobal(Offset.zero);

                // Build dynamic menu items
                final items = <PopupMenuEntry<String>>[];

                debugPrint('PostOwnerId: ${widget.postOwnerId} --debugPrint');
                if (currentUserId == widget.postOwnerId) {
                  items.add(
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Delete Post',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                items.add(
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: const [
                        Icon(
                          Icons.flag_outlined,
                          color: Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text('Report Post'),
                      ],
                    ),
                  ),
                );

                // Show popup menu
                final selected = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy + button.size.height,
                    position.dx + button.size.width,
                    position.dy,
                  ),
                  items: items,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  color: Colors.grey[900],
                );

                // Handle selection
                if (selected == 'delete') {
                  await _deletePost(context);
                } else if (selected == 'report') {
                  await _reportPost(context);
                }
              },
              icon: const Icon(
                Icons.more_horiz,
                color: Colors.white60,
                size: 18,
              ),
              padding: EdgeInsets.zero,
            ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await executeWithNetworkCheck(
          action: () => PostService.deletePost(widget.postId),
        );

        if (mounted) {
          setState(() {
            _isDeleting = false;
          });

          // Use ScaffoldMessenger.of(context) directly to ensure it shows
          ScaffoldMessenger.of(context).showSnackBar(
            _buildStyledSnackBar('Post deleted successfully!', isError: false),
          );
        }
      } catch (e) {
        debugPrint('Delete post error: $e');
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            _buildStyledSnackBar('Failed to delete post: $e', isError: true),
          );
        }
      }
    }
  }

  Future<void> _reportPost(BuildContext context) async {
    final reasonController = TextEditingController();

    final reported = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Report Post', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason for reporting',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (reported == true && mounted) {
      setState(() {
        _isReporting = true;
      });

      try {
        await executeWithNetworkCheck(
          action: () => PostService.reportPost(
            widget.postId,
            reasonController.text.trim(),
          ),
        );

        if (mounted) {
          setState(() {
            _isReporting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            _buildStyledSnackBar('Post reported successfully', isError: false),
          );
        }
      } catch (e) {
        debugPrint('Report post error: $e');
        if (mounted) {
          setState(() {
            _isReporting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            _buildStyledSnackBar('Failed to report post: $e', isError: true),
          );
        }
      }
    }

    reasonController.dispose();
  }

  SnackBar _buildStyledSnackBar(String message, {required bool isError}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
  }
}
