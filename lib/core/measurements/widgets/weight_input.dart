import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/unit_converter.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WeightInput extends ConsumerStatefulWidget {
  final double weightKg;
  final ValueChanged<double> onChangedKg;
  final Color accentColor;

  const WeightInput({
    super.key,
    required this.weightKg,
    required this.onChangedKg,
    required this.accentColor,
  });

  @override
  ConsumerState<WeightInput> createState() => _SmartWeightInputState();
}

class _SmartWeightInputState extends ConsumerState<WeightInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
        if (!_isEditing) {
          _updateTextFromExternalState();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEditing) _updateTextFromExternalState();
  }

  @override
  void didUpdateWidget(WeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) _updateTextFromExternalState();
  }

  void _updateTextFromExternalState() {
    final useLbs = ref.read(userSettingsProvider).useLbs;
    final displayVal = useLbs ? kgToLbs(widget.weightKg) : widget.weightKg;

    String newText = displayVal.toStringAsFixed(1);
    if (newText.endsWith('.0')) {
      newText = newText.substring(0, newText.length - 2);
    }

    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  void _handleTextChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      final useLbs = ref.read(userSettingsProvider).useLbs;
      final newKg = useLbs ? lbsToKg(parsed) : parsed;
      widget.onChangedKg(newKg);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));
    final unitLabel = useLbs ? 'lbs' : 'kg';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing ? widget.accentColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: context.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              onChanged: _handleTextChanged,
            ),
          ),
          
          // The Unit Label + Animated Done Button Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.cardBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  unitLabel,
                  style: context.cardTitle.copyWith(
                    color: context.textMuted,
                  ),
                ),
                
                // ─── The Inline Done Button ───
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: _isEditing
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: GestureDetector(
                            onTap: () => _focusNode.unfocus(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: widget.accentColor,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(), // Disappears when not editing
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
