import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/data/service/post_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/toast_util.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const CommentsBottomSheet({super.key, required this.post});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet>
    with NetworkAwareMixin {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  // Optimistic comments - show immediately before Firestore confirms
  final List<Map<String, dynamic>> _optimisticComments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final commentText = _commentController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    // Get user data for optimistic comment
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final userData = userDoc.data() ?? {};

    // Create optimistic comment
    final optimisticComment = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      'postId': widget.post['id'],
      'userId': currentUser.uid,
      'username':
          userData['username'] ?? currentUser.displayName ?? 'Anonymous',
      'userType': userData['userType'] ?? 'fan',
      'avatar': userData['profileImageUrl'] ?? currentUser.photoURL ?? '',
      'content': commentText,
      'timestamp': DateTime.now(), // Use current time for immediate display
      'likes': 0,
      'likedBy': [],
      'isOptimistic': true, // Flag to identify optimistic comments
    };

    // Clear input and add optimistic comment immediately
    _commentController.clear();
    setState(() {
      _isPosting = true;
      _optimisticComments.insert(0, optimisticComment); // Add to top
    });

    try {
      // Post to Firestore
      await executeWithNetworkCheck(
        action: () => PostService.addComment(
          postId: widget.post['id'],
          content: commentText,
        ),
        useToast: false, // We'll show success differently
      );

      // Remove optimistic comment after successful post
      if (mounted) {
        setState(() {
          _optimisticComments.removeWhere(
            (comment) => comment['id'] == optimisticComment['id'],
          );
        });
      }

      // Show subtle success feedback
      if (mounted) {
        ToastUtil.showToast(
          context,
          "Comment posted!",
          background: Colors.green,
          duration: const Duration(seconds: 1), // Shorter duration
        );
      }
    } catch (e) {
      debugPrint("Error posting comment: ${e.toString()}");

      // Remove failed optimistic comment and show error
      if (mounted) {
        setState(() {
          _optimisticComments.removeWhere(
            (comment) => comment['id'] == optimisticComment['id'],
          );
        });

        // Show retry option
        _showCommentErrorDialog(commentText);
      }
    }

    if (mounted) {
      setState(() => _isPosting = false);
    }
  }

  void _showCommentErrorDialog(String failedComment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Comment Failed',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Failed to post your comment. Would you like to try again?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _commentController.text = failedComment;
              _postComment();
            },
            child: const Text('Retry', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0B2E), Color(0xFF0A0A0F)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with dynamic count including optimistic comments
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.post['id'])
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int firestoreCount = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    int totalCount =
                        firestoreCount + _optimisticComments.length;

                    return Text(
                      '$totalCount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Comments list with optimistic updates
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.post['id'])
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _optimisticComments.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF9F7AEA),
                      ),
                    ),
                  );
                }

                // Combine optimistic comments with Firestore comments
                final firestoreComments = snapshot.hasData
                    ? snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return {...data, 'id': doc.id};
                      }).toList()
                    : <Map<String, dynamic>>[];

                // Merge comments: optimistic first, then Firestore
                final allComments = [
                  ..._optimisticComments,
                  ...firestoreComments,
                ];

                if (allComments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet\nBe the first to comment!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    final comment = allComments[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null, // Allow multi-line
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isPosting ? null : _postComment,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPosting
                              ? [Colors.grey.shade600, Colors.grey.shade700]
                              : [
                                  const Color(0xFF9F7AEA),
                                  const Color(0xFF6B46C1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final isOptimistic = comment['isOptimistic'] == true;
    final isLiked =
        comment['likedBy']?.contains(FirebaseAuth.instance.currentUser?.uid) ??
        false;
    final likeCount = comment['likes'] ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + optimistic dot
          Stack(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(comment['userId'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 14),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  final avatarUrl = userData?['profileImageUrl'];
                  final username =
                      userData?['username'] ?? comment['username'] ?? "User";

                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF9F7AEA),
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  );
                },
              ),

              if (isOptimistic)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: AnimatedOpacity(
              opacity: isOptimistic ? 0.8 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username from user doc
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(comment['userId'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text(
                          "Loading...",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        );
                      }
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final username =
                          userData?['username'] ??
                          comment['username'] ??
                          "User";

                      return Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 4),
                  Text(
                    comment['content'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Time, Reply, Posting...
                  Row(
                    children: [
                      Text(
                        _getTimeAgo(comment['timestamp']),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (isOptimistic) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Posting...',
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (!isOptimistic) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            ToastUtil.showToast(
                              context,
                              "Reply functionality Coming Soon!",
                              background: Colors.deepPurple,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Like button
          if (!isOptimistic)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildCommentLikeButton(comment, isLiked, likeCount),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentLikeButton(
    Map<String, dynamic> comment,
    bool isLiked,
    int likeCount,
  ) {
    return GestureDetector(
      onTap: () => _toggleCommentLike(comment['id']),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isLiked ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 23,
                color: isLiked
                    ? const Color(0xFF9F7AEA) // Purple when liked
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (likeCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$likeCount',
              style: TextStyle(
                color: isLiked
                    ? const Color(0xFF9F7AEA)
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleCommentLike(String commentId) async {
    if (commentId.startsWith('temp_')) return; // Don't like optimistic comments

    try {
      await executeWithNetworkCheck(
        action: () =>
            PostService.toggleCommentLike(widget.post['id'], commentId),
        useToast: true,
      );
      if (mounted) {
        ToastUtil.showToast(
          context,
          "Comment liked!",
          background: Colors.deepPurple,
        );
      }
    } catch (e) {
      debugPrint("Error toggling comment like: ${e.toString()}");
      if (mounted) {
        ToastUtil.showToast(
          context,
          "Failed to update like",
          background: Colors.red,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  String _getTimeAgo(dynamic timestamp) {
    DateTime? dateTime;

    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    }

    if (dateTime == null) return 'now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
