import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/workout.dart';
import '../theme.dart';
import '../icons.dart';

PageRoute<V> appRoute<V>(WidgetBuilder builder) => PageRouteBuilder<V>(
      pageBuilder: (context, _, __) => builder(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );

class Surface extends StatelessWidget {
  const Surface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = AppLayout.cardRadius,
      this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.s1,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

/// The big lime action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.play,
    this.height = AppLayout.actionHeight,
    this.color = Phase.work,
    this.foreground = Phase.onWork,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.cardRadius)),
          textStyle: T.body(16, weight: 600, height: 1.1),
        ),
        child: _CenteredButtonContent(
          label: label,
          leading: icon == null ? null : Icon(icon, size: 19),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.color,
    this.height = AppLayout.actionHeight,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? leading;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: c.s1,
          foregroundColor: color ?? c.tx,
          side: BorderSide(color: c.line),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.cardRadius)),
          textStyle: T.body(16, weight: 600, height: 1.1),
        ),
        child: _CenteredButtonContent(
          label: label,
          leading: leading ?? (icon == null ? null : Icon(icon, size: 20)),
        ),
      ),
    );
  }
}

/// Centers the label while keeping the leading icon next to its text.
class _CenteredButtonContent extends StatelessWidget {
  const _CenteredButtonContent({required this.label, this.leading});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (leading == null) return Center(child: text);
    return Center(
      child: Transform.translate(
        offset: const Offset(-14, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 28, child: Center(child: leading)),
            Flexible(child: text),
          ],
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.background,
    this.foreground,
    this.iconSize = 22,
    this.bordered = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color? foreground;
  final double iconSize;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? c.s1,
        shape: CircleBorder(
            side: bordered ? BorderSide(color: c.line) : BorderSide.none),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon,
                size: iconSize,
                color: foreground ?? c.tx,
                semanticLabel: tooltip),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: T.label(color ?? AppColors.of(context).tx));
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: T.display(34,
            color: AppColors.of(context).tx, height: 1.2, spacing: 0.4),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

/// Colored bars that preview the rhythm of a workout.
class PhaseStrip extends StatelessWidget {
  const PhaseStrip(
      {super.key,
      required this.workout,
      this.height = 6,
      this.maxBars = 14,
      this.gap = 2});

  final Workout workout;
  final double height;
  final int maxBars;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final items = <WorkInterval>[];
    for (final b in workout.blocks) {
      items.addAll(b.intervals);
    }
    final shown = items.take(maxBars).where((i) => i.seconds > 0).toList();
    if (shown.isEmpty) return SizedBox(height: height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                flex: shown[i].seconds.clamp(5, 600),
                child: Container(color: Phase.fill(shown[i].type)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal chips with ready-made names. Tapping one fills the text field.
class NameChips extends StatelessWidget {
  const NameChips(
      {super.key, required this.names, required this.onPick, this.selected});

  final List<String> names;
  final ValueChanged<String> onPick;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final on = names[i] == selected;
          return Material(
            color: on ? c.tx : c.s2,
            shape: StadiumBorder(side: BorderSide(color: on ? c.tx : c.line)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                onPick(names[i]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(names[i],
                      style: T.body(14, weight: 600, color: on ? c.bg : c.tx)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField(
      {super.key,
      required this.controller,
      this.hint,
      this.autofocus = false,
      this.onSubmitted});

  final TextEditingController controller;
  final String? hint;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: T.body(17, weight: 600, color: c.tx),
      cursorColor: c.tx,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: T.body(17, color: c.mu),
        filled: true,
        fillColor: c.s2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(AppIcons.clear, color: c.faint),
                  onPressed: controller.clear,
                ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.tx, width: 1.5)),
      ),
    );
  }
}

/// Segmented selector for the interval type.
class TypeSelector extends StatelessWidget {
  const TypeSelector(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.labelOf});

  final IntervalType value;
  final ValueChanged<IntervalType> onChanged;
  final String Function(IntervalType) labelOf;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (final t in IntervalType.values)
            Expanded(
              child: Semantics(
                selected: t == value,
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t == value ? Phase.fill(t) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labelOf(t),
                      textAlign: TextAlign.center,
                      style: T.body(16,
                          weight: 600, color: t == value ? Phase.on(t) : c.mu),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
