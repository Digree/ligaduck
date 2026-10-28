import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

Color? _accent(Color? textColor, Widget? icon, Color? iconColor) {
  if (iconColor != null) return iconColor;
  if (icon is Icon && icon.color != null) return icon.color;
  return textColor;
}

String? _textOf(Widget? w) {
  if (w == null) return null;
  if (w is Text) return w.data ?? w.textSpan?.toPlainText();
  if (w is Row) return _firstText(w.children);
  if (w is Column) return _firstText(w.children);
  if (w is Flexible) return _textOf(w.child);
  if (w is Padding) return _textOf(w.child);
  if (w is SizedBox) return _textOf(w.child);
  if (w is Container) return _textOf(w.child);
  if (w is Align) return _textOf(w.child);
  if (w is Center) return _textOf(w.child);
  return null;
}

String? _firstText(List<Widget> children) {
  final parts = children.map(_textOf).whereType<String>().toList();
  return parts.isEmpty ? null : parts.join(' ');
}

/// Native Liquid Glass menu used as a dropdown. Returns null when the items
/// can't be represented as plain text.
Widget? _buildNativeMenu<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?>? onChanged,
  Widget? hint,
  bool isExpanded = false,
  Color? color,
}) {
  if (!NativeLiquidGlassUtils.supportsLiquidGlass ||
      onChanged == null ||
      items.isEmpty) {
    return null;
  }
  final titles = items.map((i) => _textOf(i.child)).toList();
  if (titles.any((t) => t == null)) return null;

  final selectedIndex = items.indexWhere((i) => i.value == value);
  final label = selectedIndex >= 0
      ? titles[selectedIndex]!
      : (_textOf(hint) ?? 'Seleziona');

  final menu = LiquidGlassMenu(
    key: ValueKey('$label|${items.length}'),
    label: label,
    color: color,
    items: [
      for (var i = 0; i < items.length; i++)
        LiquidGlassMenuItem(
          id: '$i',
          title: titles[i]!,
          isDisabled: !items[i].enabled,
          icon: i == selectedIndex
              ? const NativeLiquidGlassIcon.sfSymbol('checkmark')
              : null,
        ),
    ],
    onItemSelected: (id) {
      final index = int.tryParse(id);
      if (index != null) onChanged(items[index].value);
    },
  );
  return Align(alignment: Alignment.centerLeft, child: menu);
}

class LiquidGlassDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final bool isExpanded;
  final TextStyle? style;
  final Color? dropdownColor;
  final Color? iconEnabledColor;
  final Widget? icon;
  final Widget? underline;
  final double? menuMaxHeight;
  final BorderRadius? borderRadius;
  final bool isDense;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const LiquidGlassDropdownButton({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.isExpanded = false,
    this.style,
    this.dropdownColor,
    this.iconEnabledColor,
    this.icon,
    this.underline,
    this.menuMaxHeight,
    this.borderRadius,
    this.isDense = false,
    this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final native = _buildNativeMenu<T>(
      value: value,
      items: items ?? const [],
      onChanged: onChanged,
      hint: hint,
      isExpanded: isExpanded,
      color: _accent(style?.color, icon, iconEnabledColor),
    );
    if (native != null) return native;

    return DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
      isExpanded: isExpanded,
      style: style,
      dropdownColor: dropdownColor,
      iconEnabledColor: iconEnabledColor,
      icon: icon ?? const Icon(Icons.arrow_drop_down),
      underline: underline ?? const SizedBox.shrink(),
      menuMaxHeight: menuMaxHeight,
      borderRadius: borderRadius,
      isDense: isDense,
      selectedItemBuilder: selectedItemBuilder,
    );
  }
}

class LiquidGlassDropdownButtonFormField<T> extends StatelessWidget {
  final T? initialValue;
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final InputDecoration? decoration;
  final Widget? hint;
  final bool isExpanded;
  final TextStyle? style;
  final Color? dropdownColor;
  final Color? iconEnabledColor;
  final Widget? icon;
  final double? menuMaxHeight;
  final BorderRadius? borderRadius;
  final bool isDense;
  final AutovalidateMode? autovalidateMode;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const LiquidGlassDropdownButtonFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.value,
    this.validator,
    this.onSaved,
    this.decoration,
    this.hint,
    this.isExpanded = false,
    this.style,
    this.dropdownColor,
    this.iconEnabledColor,
    this.icon,
    this.menuMaxHeight,
    this.borderRadius,
    this.isDense = true,
    this.autovalidateMode,
    this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? initialValue;
    final titlesOk =
        NativeLiquidGlassUtils.supportsLiquidGlass &&
        onChanged != null &&
        (items ?? const []).isNotEmpty &&
        items!.every((i) => _textOf(i.child) != null);

    if (!titlesOk) {
      return DropdownButtonFormField<T>(
        initialValue: current,
        items: items,
        onChanged: onChanged,
        validator: validator,
        onSaved: onSaved,
        decoration: decoration ?? const InputDecoration(),
        hint: hint,
        isExpanded: isExpanded,
        style: style,
        dropdownColor: dropdownColor,
        iconEnabledColor: iconEnabledColor,
        icon: icon ?? const Icon(Icons.arrow_drop_down),
        menuMaxHeight: menuMaxHeight,
        borderRadius: borderRadius,
        isDense: isDense,
        autovalidateMode: autovalidateMode,
        selectedItemBuilder: selectedItemBuilder,
      );
    }

    return FormField<T>(
      key: ValueKey(current),
      initialValue: current,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      builder: (state) {
        return InputDecorator(
          decoration: (decoration ?? const InputDecoration()).copyWith(
            errorText: state.errorText,
          ),
          isEmpty: false,
          child: _buildNativeMenu<T>(
            value: state.value,
            items: items!,
            onChanged: (v) {
              state.didChange(v);
              onChanged!(v);
            },
            hint: hint,
            isExpanded: isExpanded,
            color: _accent(style?.color, icon, iconEnabledColor),
          )!,
        );
      },
    );
  }
}

/// Riquadro standard dei dropdown, come il selettore squadre della home campionato.
class LiquidGlassDropdownBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  const LiquidGlassDropdownBox({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color ?? Colors.blueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// Wrapper dei campi di testo. Non applica più alcun effetto vetro:
/// i contenitori Liquid Glass attorno ai campi di input causavano glitch
/// grafici (artefatti di rendering, soprattutto dentro dialog e liste
/// scrollabili come "Assegna numeri"). Il widget resta come semplice
/// passthrough per non dover toccare i ~40 call site esistenti.
class LiquidGlassTextBox extends StatelessWidget {
  final Widget child;
  const LiquidGlassTextBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
