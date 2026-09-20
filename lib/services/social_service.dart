import '../models/social_post.dart';
import 'mock_football_service.dart';
import 'poisson_engine.dart';

class SocialService {
  static final List<SocialPost> _posts = [];

  static List<SocialPost> getPosts() {
    if (_posts.isEmpty) {
      _generateMockPosts();
    }
    return _posts;
  }

  static void addPost(SocialPost post) {
    _posts.insert(0, post);
  }

  static void _generateMockPosts() {
    final teams = MockFootballService.getMockTeams();
    
    final p1 = PoissonEngine.calculatePrediction(homeTeam: teams[0], awayTeam: teams[1]);
    final p2 = PoissonEngine.calculatePrediction(homeTeam: teams[2], awayTeam: teams[3]);

    _posts.addAll([
      SocialPost(
        id: '1',
        username: 'FutbolAnaliz_TR',
        userAvatar: 'https://i.pravatar.cc/150?u=1',
        content: 'Galatasaray bu formuyla evinde hata yapmaz. Poisson modelim %65 galibiyet diyor!',
        prediction: p1,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 24,
      ),
      SocialPost(
        id: '2',
        username: 'BahisSihirbazi',
        userAvatar: 'https://i.pravatar.cc/150?u=2',
        content: 'Fenerbahçe deplasmanda zorlanabilir ama 2.5 Üst seçeneği çok değerli duruyor.',
        prediction: p2,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 12,
      ),
    ]);
  }
}
