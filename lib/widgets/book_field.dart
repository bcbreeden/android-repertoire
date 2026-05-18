import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A text field with autocomplete suggestions drawn from [bookNames].
/// Because [Autocomplete] owns its internal [TextEditingController], callers
/// receive a reference via [onControllerReady] so they can read the value at
/// save time. The field is pre-filled with [initialValue].
class BookField extends StatelessWidget {
  final String initialValue;
  final List<String> bookNames;
  final ValueChanged<TextEditingController> onControllerReady;

  const BookField({
    super.key,
    required this.initialValue,
    required this.bookNames,
    required this.onControllerReady,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const [];
        return bookNames
            .where((b) => b.toLowerCase().contains(query))
            .toList();
      },
      onSelected: (selection) {
        // fieldViewBuilder's controller is updated automatically by Autocomplete
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: kCardColor,
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Text(
                        option,
                        style: const TextStyle(
                            color: kTextPrimary, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        // Deliver the controller reference on first build.
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => onControllerReady(textEditingController));
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: const TextStyle(color: kTextPrimary),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Book',
            hintText: 'e.g. Alfred Adult Piano, Royal Conservatory',
            labelStyle: const TextStyle(color: kTextSecondary),
            hintStyle:
                TextStyle(color: kTextSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: kCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: kGoldColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        );
      },
    );
  }
}
