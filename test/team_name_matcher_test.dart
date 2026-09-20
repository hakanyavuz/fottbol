import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/core/utils/team_name_matcher.dart';

void main() {
  group('TeamNameMatcher Tests', () {
    test('Identical or case/accent variations match', () {
      expect(TeamNameMatcher.matches('Fenerbahçe', 'Fenerbahce'), isTrue);
      expect(TeamNameMatcher.matches('Beşiktaş', 'Besiktas'), isTrue);
      expect(TeamNameMatcher.matches('Gaziantep FK', 'Gaziantep'), isTrue);
      expect(TeamNameMatcher.matches('Galatasaray A.Ş.', 'Galatasaray'), isTrue);
      expect(TeamNameMatcher.matches('Istanbul Basaksehir', 'Başakşehir FK'), isTrue);
    });

    test('Different teams NEVER match', () {
      // The bug that occurred: Amed SFK was matched with Gaziantep FK
      expect(TeamNameMatcher.matches('Amed SFK', 'Gaziantep FK'), isFalse);
      expect(TeamNameMatcher.matches('Istanbul Basaksehir', 'Fenerbahçe'), isFalse);
      expect(TeamNameMatcher.matches('Trabzonspor', 'Samsunspor'), isFalse);
      expect(TeamNameMatcher.matches('Real Madrid', 'Real Sociedad'), isFalse);
      expect(TeamNameMatcher.matches('Manchester City', 'Manchester United'), isFalse);
    });

    test('Empty names do not match', () {
      expect(TeamNameMatcher.matches('', 'Fenerbahçe'), isFalse);
      expect(TeamNameMatcher.matches('', ''), isFalse);
    });
  });
}
