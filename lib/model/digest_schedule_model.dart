import 'package:the_news/model/daily_digest_model.dart';

class DigestSchedule {
  final List<TimeOfDay> times;
  final Set<int> weekdays; // 1-7, Monday-Sunday
  final bool enabled;

  const DigestSchedule({
    required this.times,
    required this.weekdays,
    this.enabled = true,
  });
}