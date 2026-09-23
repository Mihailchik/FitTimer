import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../models/workout.dart';
import '../theme.dart';
import '../icons.dart';
import '../widgets/common.dart';
import 'run_screen.dart';

class RunSummary {
  final Workout workout;
  final Duration elapsed;
  final Duration work;
  final Duration rest;
  final int intervalsDone;
  final int intervalsTotal;
  final bool early;

  const RunSummary({
    required this.workout,
    required this.elapsed,
    required this.work,
    required this.rest,
    required this.intervalsDone,
    required this.intervalsTotal,
    required this.early,
  });
}

class FinishScreen extends StatelessWidget {
  const FinishScreen({super.key, required this.summary});
  final RunSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);

    Widget stat(String label, Color color, String value) => SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: T.body(15, color: color, weight: 600))),
              Text(value, style: T.display(24, color: c.tx, height: 1.0)),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: PageWidth(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppLayout.pageInset, 32, AppLayout.pageInset, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: summary.early ? c.chip : Phase.work,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: summary.early
                        ? Icon(AppIcons.finish, size: 44, color: c.tx)
                        : const Icon(AppIcons.check,
                            size: 48, color: Phase.onWork),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                summary.early ? s.stoppedEarly : s.wellDone,
                textAlign: TextAlign.center,
                style: T.display(summary.early ? 28 : 34,
                    color: c.tx, height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(summary.workout.name,
                  textAlign: TextAlign.center, style: T.body(15, color: c.mu)),
              const SizedBox(height: 28),
              Surface(
                radius: 18,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Column(children: [
                  stat(s.time, c.mu, formatClock(summary.elapsed.inSeconds)),
                  Divider(height: 1, color: c.line),
                  stat(
                      s.intervals,
                      c.mu,
                      s.intervalsProgress(
                          summary.intervalsDone, summary.intervalsTotal)),
                  Divider(height: 1, color: c.line),
                  stat(s.work, c.work, formatClock(summary.work.inSeconds)),
                  Divider(height: 1, color: c.line),
                  stat(s.rest, c.rest, formatClock(summary.rest.inSeconds)),
                ]),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: s.repeat,
                      onPressed: () {
                        Navigator.of(context).pop();
                        openRun(context, summary.workout);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                        label: s.done,
                        icon: null,
                        onPressed: () => Navigator.of(context).pop()),
                  ),
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }
}
