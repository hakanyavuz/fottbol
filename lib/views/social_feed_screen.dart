import 'package:flutter/material.dart';
import '../models/social_post.dart';
import '../services/social_service.dart';
import '../widgets/score_board_card.dart';
import 'prediction_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  late List<SocialPost> _posts;

  @override
  void initState() {
    super.initState();
    _posts = SocialService.getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Tahmin Paylaşım Akışı'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(post.userAvatar),
                  ),
                  title: Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatTime(post.createdAt), style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(post.content),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PredictionScreen(historyItem: post.prediction)),
                    ),
                    child: IgnorePointer(
                      child: ScoreBoardCard(prediction: post.prediction),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : null,
                        ),
                        onPressed: () {
                          setState(() {
                            post.isLiked = !post.isLiked;
                            post.isLiked ? post.likes++ : post.likes--;
                          });
                        },
                      ),
                      Text('${post.likes}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPostDialog(context),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }

  void _showAddPostDialog(BuildContext context) {
    // Bu kısım gerçek bir uygulamada kullanıcının son tahminlerini seçebileceği bir arayüz olurdu.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tahmin paylaşma özelliği simüle edildi!')),
    );
  }
}
