import 'package:flutter/material.dart';

class ComboItemDialog extends StatefulWidget {
  final List products;

  const ComboItemDialog({super.key, required this.products});

  @override
  State<ComboItemDialog> createState() => ComboItemDialogState();
}

class ComboItemDialogState extends State<ComboItemDialog> {
  int? _productId;
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm/cập nhật hoa"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _productId,
            decoration: const InputDecoration(labelText: "Hoa đơn"),
            items: widget.products.map((raw) {
              final product = Map<String, dynamic>.from(raw as Map);
              final id = product['productId'] ?? product['id'] ?? 0;
              return DropdownMenuItem(
                value: id as int,
                child: Text(
                  product['productName'] ?? product['name'] ?? "Hoa #$id",
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _productId = value),
          ),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Số lượng"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _productId == null
              ? null
              : () => Navigator.pop(context, (
                  _productId!,
                  int.tryParse(_quantityController.text) ?? 1,
                )),
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
