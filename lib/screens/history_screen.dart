import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/session_repository.dart';

class HistoryScreen extends StatefulWidget {
  static const String routeName = '/history';
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await SessionRepository.instance.getAll();
    if (mounted) setState(() { _sessions = sessions; _loading = false; });
  }

  // Remove from local list immediately so the swipe-dismiss animation completes
  // without a spinner interrupting it. The DB write happens in the background.
  void _deleteOptimistic(Session session) {
    if (session.id == null) return;
    setState(() => _sessions.removeWhere((s) => s.id == session.id));
    SessionRepository.instance.delete(session.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Session History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00), strokeWidth: 2),
            )
          : _sessions.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: _sessions.length,
                  itemBuilder: (context, i) => _SessionCard(
                    session: _sessions[i],
                    onDelete: _deleteOptimistic,
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Icon(Icons.sports_basketball_outlined, size: 40, color: Color(0xFF444444)),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No sessions yet',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Your completed sessions will appear here.',
            style: TextStyle(color: Color(0xFF666666), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final void Function(Session) onDelete;

  const _SessionCard({required this.session, required this.onDelete});

  Color _scoreColor(double pct) {
    if (pct < 50) return Colors.redAccent;
    if (pct < 70) return Colors.amber;
    if (pct < 88) return const Color(0xFFFF6B00);
    return Colors.greenAccent;
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = session.overallScore >= 0;
    final pct = hasScore ? (session.overallScore * 100).clamp(0.0, 100.0) : 0.0;

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      // confirmDismiss only decides whether to dismiss — no state changes here.
      confirmDismiss: (_) async => session.id != null,
      // onDismissed fires after the slide-out animation completes.
      onDismissed: (_) => onDelete(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hasScore
                  ? _scoreColor(pct).withValues(alpha: 0.12)
                  : const Color(0xFF242424),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: hasScore
                  ? Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _scoreColor(pct),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : const Text('—',
                      style: TextStyle(
                          color: Color(0xFF666666), fontSize: 20, fontWeight: FontWeight.w300)),
            ),
          ),
          title: Text(
            _relativeDate(session.date),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${session.shotCount} shot${session.shotCount == 1 ? '' : 's'} detected',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF444444)),
        ),
      ),
    );
  }
}
