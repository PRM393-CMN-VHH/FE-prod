import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';

class CheckoutDeliveryForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController notesController;

  const CheckoutDeliveryForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Thông tin giao hàng", style: textTheme.titleLarge),
        const SizedBox(height: 12),
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Người nhận",
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppMessage.recipientNameRequired.text;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Số điện thoại",
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppMessage.phoneRequired.text;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Địa chỉ giao hàng",
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppMessage.deliveryAddressRequired.text;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: "Ghi chú giao hàng (không bắt buộc)",
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    );
  }
}
