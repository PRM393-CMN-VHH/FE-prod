import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/toast_provider.dart';
import 'package:prm393/theme/app_theme.dart';

class TopToastOverlay extends StatelessWidget {
  final Widget child;

  const TopToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        SafeArea(
          child: Consumer<ToastProvider>(
            builder: (context, toast, _) {
              if (toast.message == null) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      color: toast.isError
                          ? Colors.redAccent
                          : AppTheme.primaryColor,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: toast.clear,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                toast.isError
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  toast.message!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
