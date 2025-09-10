import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/data/service/post_service.dart';
import 'package:phonkers/view/widget/community_widget/comments_bottum_sheets.dart';
import 'package:phonkers/view/widget/community_widget/community_feed_highlighter.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/toast_util.dart';
import 'post_card.dart';

class CommunityFeed extends StatefulWidget {
  final String userType;
  final String feedType;

  const CommunityFeed({
    super.key,
    required this.userType,
    required this.feedType,
  });

  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed>
    with AutomaticKeepAliveClientMixin, NetworkAwareMixin {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToHighlighted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Reset scroll flag when feed is created
    _hasScrolledToHighlighted = false;
  }

  void _scrollToHighlightedPost(List<Map<String, dynamic>> posts) {
    if (_hasScrolledToHighlighted) return;

    final highlightedId = CommunityFeedHighlighter.highlightedPostId;
    if (highlightedId == null) return;

    final index = posts.indexWhere((post) => post['id'] == highlightedId);
    if (index == -1) return;

    _hasScrolledToHighlighted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController
            .animateTo(
              index * 300.0, // estimate average post height
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            )
            .then((_) {
              // Clear highlight after a delay
              Future.delayed(const Duration(seconds: 5), () {
                CommunityFeedHighlighter.clearHighlight();
              });
            });
      }
    });
  }

  void _onCommentPressed(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommentsBottomSheet(post: post),
      ),
    );
  }

  Future<void> _onLikePressed(String postId) async {
    await executeWithNetworkCheck(
      action: () => PostService.toggleLike(postId),
      useToast: true,
    );
    if (mounted) {
      ToastUtil.showToast(
        context,
        "Post liked!",
        background: Colors.deepPurple,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9F7AEA)),
            ),
          );
        }

        if (snapshot.hasError) {
          return buildNoInternetError(
            onRetry: () {},
            message: 'Something went wrong. Please try again.',
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share something!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Check if we need to scroll to a highlighted post
        _scrollToHighlightedPost(posts);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          backgroundColor: const Color(0xFF1A0B2E),
          color: const Color(0xFF9F7AEA),
          child: ValueListenableBuilder(
            valueListenable: CommunityFeedHighlighter.notifier,
            builder: (context, _, __) {
              return ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 100),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final highlight = CommunityFeedHighlighter.shouldHighlight(
                    post['id'],
                  );

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: highlight
                            ? Colors.deepPurpleAccent
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: highlight
                          ? [
                              BoxShadow(
                                color: Colors.deepPurpleAccent.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: PostCard(
                      post: post,
                      onLikePressed: () => _onLikePressed(post['id']),
                      onCommentPressed: () => _onCommentPressed(post),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
