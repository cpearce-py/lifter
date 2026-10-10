import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/providers/templates_provider.dart';
import 'package:lifter/features/workouts/ui/builder/block_editor_page.dart';
import 'package:lifter/features/workouts/ui/builder/builder_widgets.dart';

/// Creates a new template, or edits [template] when one is given.
class TemplateEditorPage extends ConsumerStatefulWidget {
  const TemplateEditorPage({super.key, this.template});

  final WorkoutTemplate? template;

  @override
  ConsumerState<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage> {
  late WorkoutTemplate _template;
  late final TextEditingController _nameController;
  bool _dirty = false;
  bool _saving = false;

  bool get _isNew => widget.template == null;

  @override
  void initState() {
    super.initState();
    _template = widget.template ??
        WorkoutTemplate(
          name: '',
          startingHand: ref.read(userSettingsProvider).preferredHand,
          blocks: const [WorkoutBlock.warmup(), WorkoutBlock.working()],
        );
    _nameController = TextEditingController(text: _template.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(WorkoutTemplate template) {
    setState(() {
      _template = template;
      _dirty = true;
    });
  }

  void _setBlocks(List<WorkoutBlock> blocks) =>
      _update(_template.copyWith(blocks: blocks));

  Future<void> _editBlock(int? index, WorkoutBlock block) async {
    final result = await Navigator.of(context).push<WorkoutBlock>(
      CupertinoPageRoute(
        builder: (_) => BlockEditorPage(block: block, isNew: index == null),
      ),
    );
    if (result == null) return;

    final blocks = [..._template.blocks];
    if (index == null) {
      blocks.add(result);
    } else {
      blocks[index] = result;
    }
    _setBlocks(blocks);
  }

  void _removeBlock(int index) {
    HapticFeedback.lightImpact();
    _setBlocks([..._template.blocks]..removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    final blocks = [..._template.blocks];
    final block = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, block);
    _setBlocks(blocks);
  }

  bool get _canSave =>
      !_saving &&
      _nameController.text.trim().isNotEmpty &&
      _template.blocks.isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final toSave = _template.copyWith(name: _nameController.text.trim());
    await ref.read(templatesProvider.notifier).saveTemplate(toSave);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBackground,
        title: Text('Discard changes?', style: context.body),
        content: Text(
          'Your changes to this workout will be lost.',
          style: TextStyle(color: context.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep editing', style: TextStyle(color: context.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: TextStyle(color: context.danger)),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.customAccent;
    final blocks = _template.blocks;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Navigator.pop skips PopScope, so this closes the page.
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: BuilderScaffold(
        backLabel: 'Workouts',
        title: _isNew ? 'New workout' : 'Edit workout',
        subtitle: blocks.isEmpty
            ? 'Add a warm-up and some working sets'
            : '${blocks.length} blocks · ${formatEstimate(_template.estimatedSeconds)}',
        accentColor: accentColor,
        buttonLabel: _isNew ? 'Create workout' : 'Save workout',
        onButtonTap: _canSave ? _save : null,
        children: [
          AppCard(
            label: 'Name',
            child: BuilderTextField(
              controller: _nameController,
              hintText: 'e.g. Max hangs',
              onChanged: (_) => setState(() => _dirty = true),
            ),
          ),
          AppCard(
            label: 'Starting hand',
            child: SegmentedControl(
              choices: Hand.values.map((h) => h.label).toList(),
              selectedIndex: _template.startingHand.index,
              accentColor: accentColor,
              onChanged: (i) =>
                  _update(_template.copyWith(startingHand: Hand.values[i])),
            ),
          ),
          if (blocks.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: blocks.length,
              onReorderItem: _reorder,
              proxyDecorator: (child, _, _) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (context, i) => Padding(
                key: ObjectKey(blocks[i]),
                padding: const EdgeInsets.only(bottom: 10),
                child: BlockCard(
                  index: i,
                  block: blocks[i],
                  onTap: () => _editBlock(i, blocks[i]),
                  onDelete: () => _removeBlock(i),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _AddBlockButton(
                  label: 'Add warm-up',
                  color: context.warmupAccent,
                  onTap: () => _editBlock(null, const WorkoutBlock.warmup()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AddBlockButton(
                  label: 'Add working',
                  color: accentColor,
                  onTap: () => _editBlock(null, const WorkoutBlock.working()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BlockCard extends StatelessWidget {
  const BlockCard({
    super.key,
    required this.index,
    required this.block,
    this.onTap,
    this.onDelete,
    this.trailing,
  });

  final int index;
  final WorkoutBlock block;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final kindColor = block.kind == BlockKind.warmup
        ? context.warmupAccent
        : context.customAccent;
    final editable = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kindColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: kindColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.kind.label.toUpperCase(),
                    style: context.overline.copyWith(
                      color: kindColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    block.name,
                    style: context.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blockSummary(block),
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ],
              ),
            ),
            ?trailing,
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: context.textMuted),
                onPressed: onDelete,
              ),
            if (editable)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle_rounded, color: context.textSubtle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddBlockButton extends StatelessWidget {
  const _AddBlockButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
