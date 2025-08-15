/// Simple mock [Challenge] data for UI testing.
class Challenge {
  const Challenge({
    required this.title,
    required this.description,
    required this.tags,
    required this.author,
    required this.createdAt,
    required this.score,
  });

  final String title;
  final String description;
  final List<String> tags;
  final String author;
  final DateTime createdAt;
  final int score;
}

final List<Challenge> mockChallenges = [
  Challenge(
    title: '30-day coding challenge',
    description: 'Write code every day for 30 days and share progress.',
    tags: ['coding', 'habit'],
    author: 'Jane Doe',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    score: 42,
  ),
  Challenge(
    title: 'Read a book a week',
    description: 'Select a book and finish it within a week.',
    tags: ['reading', 'learning'],
    author: 'John Smith',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    score: 12,
  ),
];
