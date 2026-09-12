import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import '../utils/field_hint_utils.dart';

/// Standard labeled text field used across all forms.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixWidget,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.helperText,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.textInputAction,
    this.initialValue,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? suffixText;
  final String? helperText;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final TextInputAction? textInputAction;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;
  TextEditingController? _internalController;

  TextEditingController get _controller {
    if (widget.controller != null) return widget.controller!;
    if (_internalController == null) {
      _internalController = TextEditingController(text: widget.initialValue);
      _internalController!.addListener(_onTextChanged);
    }
    return _internalController!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
      
      if (widget.controller != null && _internalController != null) {
        _internalController?.dispose();
        _internalController = null;
      } else if (widget.controller == null && _internalController == null) {
        _internalController = TextEditingController(text: widget.initialValue);
        _internalController!.addListener(_onTextChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label?.trim();
    final generatedHint = label == null || label.isEmpty
        ? widget.hint
        : widget.readOnly && widget.onTap != null
        ? selectHintForLabel(label)
        : enterHintForLabel(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          if (widget.label!.contains('*'))
            RichText(
              text: TextSpan(
                text: context.tr(widget.label!.replaceAll('*', '').trimRight()),
                style: context.text.titleSmall,
                children: [
                  TextSpan(
                    text: ' *',
                    style: context.text.titleSmall?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            )
          else
            Text(context.tr(widget.label!), style: context.text.titleSmall),
          AppSizes.vGapSm,
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          initialValue: widget.initialValue,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted ?? (_) => FocusScope.of(context).nextFocus(),
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction ??
              (widget.maxLines == 1
                  ? TextInputAction.next
                  : TextInputAction.newline),
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hint == null
                ? context.tr(generatedHint ?? "")
                : context.tr(widget.hint!),
            prefixText: widget.prefixText,
            prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
            prefixIcon: widget.prefixWidget ??
                (widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, size: AppSizes.iconMd)
                    : null),
            suffixText: widget.suffixText,
            suffixStyle: const TextStyle(fontWeight: FontWeight.w600),
            helperText: widget.helperText,
            suffixIcon: _buildSuffixIcon(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscure) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: AppSizes.iconMd,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }

    final isRequired = widget.label?.contains('*') == true;
    final isEmpty = _controller.text.trim().isEmpty;
    final isValid = widget.validator == null || widget.validator!(_controller.text) == null;
    final isEmail = widget.keyboardType == TextInputType.emailAddress || 
                    (widget.label?.toLowerCase().contains('email') == true);
    
    final shouldShowGreenCheck = isEmail ? (!isEmpty && isValid) : !isEmpty;

    if (isRequired && isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.suffixIcon != null) widget.suffixIcon!,
          const Padding(
            padding: EdgeInsets.only(right: 12.0, left: 4.0),
            child: Text(
              '*',
              style: TextStyle(color: Colors.red, fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (shouldShowGreenCheck) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.suffixIcon != null) widget.suffixIcon!,
          const Padding(
            padding: EdgeInsets.only(right: 12.0, left: 4.0),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 18,
            ),
          ),
        ],
      );
    }

    return widget.suffixIcon;
  }
}

