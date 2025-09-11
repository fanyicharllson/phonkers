import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/community_widget/post_more_options.dart';
import 'package:phonkers/view/widget/toast_util.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Future<void> Function() onLikePressed;
  final void Function() onCommentPressed;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikePressed,
    required this.onCommentPressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'artist':
        return const Color(0xFFE879F9);
      case 'producer':
        return const Color(0xFF06B6D4);
      case 'collector':
        return const Color(0xFF10B981);
      case 'fan':
        return const Color(0xFFF59E0B);
      case 'dj':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9F7AEA);
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType) {
      case 'artist':
        return Icons.mic;
      case 'producer':
        return Icons.equalizer;
      case 'collector':
        return Icons.library_music;
      case 'fan':
        return Icons.favorite;
      case 'dj':
        return Icons.headphones;
      default:
        return Icons.person;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTypeColor = _getUserTypeColor(widget.post['userType']);

    // Safely get timestamp as non-nullable DateTime
    DateTime timestamp;
    final ts = widget.post['timestamp'];

    if (ts != null) {
      timestamp = ts is DateTime ? ts : ts.toDate();
    } else {
      timestamp = DateTime.now(); // fallback if null
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: userTypeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // User Header
          _buildUserHeader(userTypeColor, timestamp),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.post['content'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Music Track (if available)
          if (widget.post['musicTrack'] != null) _buildMusicTrack(),

          // Post Image (if available)
          if (widget.post['hasImage'] == true) _buildPostImage(),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildUserHeader(Color userTypeColor, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.post['userId'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade800,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;

                  final avatarUrl = userData?['profileImageUrl'];
                  final username =
                      userData?['username'] ?? widget.post['username'];

                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: userTypeColor.withValues(alpha: 0.3),
                    child: CircleAvatar(
                      radius: 18,
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
                    ),
                  );
                },
              ),

              // Badge
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: userTypeColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    _getUserTypeIcon(widget.post['userType']),
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.post['userId'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            );
                          }
                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final username =
                              userData?['username'] ?? widget.post['username'];
                          return Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: userTypeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: userTypeColor.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        widget.post['userType'].toUpperCase(),
                        style: TextStyle(
                          color: userTypeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getTimeAgo(timestamp),
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),

          // More options
          SizedBox(
            width: 32,
            height: 32,
            child: PostMoreOptions(
              postId: widget.post['id'],
              postOwnerId: widget.post['userId'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicTrack() {
    final track = widget.post['musicTrack'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9F7AEA).withValues(alpha: 0.1),
            const Color(0xFF6B46C1).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9F7AEA).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Music icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9F7AEA), Color(0xFF6B46C1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),

          // Track info - Flexible to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track['artist'],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Waveform visualization
                Row(
                  children: List.generate(
                    (track['waveform'].length).clamp(0, 12),
                    (index) => Container(
                      width: 2.5,
                      height: (15 * track['waveform'][index]).toDouble(),
                      margin: const EdgeInsets.only(right: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9F7AEA).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Play button and duration
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Play/pause track
                },
                icon: const Icon(
                  Icons.play_circle_filled,
                  color: Color(0xFF9F7AEA),
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              Text(
                track['duration'],
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9F7AEA).withValues(alpha: 0.3),
            const Color(0xFF6B46C1).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.white30),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _ActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(widget.post['likes']),
            color: _isLiked ? Colors.red : Colors.white60,
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
              //! Todo
              ToastUtil.showToast(
                context,
                "Liking post... please wait",
                background: Colors.deepPurple,
              );
              widget.onLikePressed();
            },
          ),
          const SizedBox(width: 20),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.post['comments']),
            color: Colors.white60,
            onTap: () {
              widget.onCommentPressed(); //!check this again
            },
          ),
          const SizedBox(width: 20),
          _ActionButton(
            icon: Icons.share,
            label: _formatCount(widget.post['shares']),
            color: Colors.white60,
            onTap: () {
              // TODO: Handle share
              ToastUtil.showToast(
                context,
                "Post Sharing Coming Soon!",
                background: Colors.deepPurple,
              );
            },
          ),
          const Spacer(),
          _ActionButton(
            icon: Icons.bookmark_border,
            label: '',
            color: Colors.white60,
            onTap: () {
              // TODO: Handle bookmark
              ToastUtil.showToast(
                context,
                "Post bookmark Coming Soon!",
                background: Colors.deepPurple,
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
