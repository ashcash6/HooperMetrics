import 'dart:convert';

class Session {
  final int? id;
  final DateTime date;
  final double overallScore;
  final Map<String, double> detailedScores;
  final List<String> tips;
  final int shotCount;

  const Session({
    this.id,
    required this.date,
    required this.overallScore,
    required this.detailedScores,
    required this.tips,
    required this.shotCount,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.millisecondsSinceEpoch,
        'overall_score': overallScore,
        'detailed_scores': jsonEncode(detailedScores),
        'tips': jsonEncode(tips),
        'shot_count': shotCount,
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        overallScore: (map['overall_score'] as num).toDouble(),
        detailedScores: Map<String, double>.from(
          (jsonDecode(map['detailed_scores'] as String) as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ),
        ),
        tips: List<String>.from(jsonDecode(map['tips'] as String) as List),
        shotCount: map['shot_count'] as int,
      );
}
