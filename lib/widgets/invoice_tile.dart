import 'package:flutter/material.dart';

import '../models/invoice_list_model.dart';
import '../utility/app_theme.dart';
import '../utility/global_function.dart';
import 'common_widgets.dart';

class InvoiceTile extends StatelessWidget {
  const InvoiceTile({
    super.key,
    required this.invoice,
    required this.onTap,
    this.onShare,
    this.onEdit,
    this.hero = true,
  });

  final InvoiceData invoice;
  final VoidCallback onTap;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;

  /// Only one list on screen may use the hero, or Flutter reports duplicate tags.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = invoice.customerName.isEmpty ? "Unnamed customer" : invoice.customerName;
    final showActions = onShare != null || onEdit != null;
    return Pressable(
      onTap: onTap,
      scale: .98,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 10, showActions ? 4 : 14, 10),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            hero
                ? Hero(
                    tag: 'avatar-${invoice.id ?? invoice.invoiceNumber}',
                    child: InitialsAvatar(text: initials(name), seed: name),
                  )
                : InitialsAvatar(text: initials(name), seed: name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(invoice.invoiceNumber ?? '', style: AppTheme.mono(size: 11.5, color: p.muted)),
                  const SizedBox(height: 2),
                  Text(
                    showActions
                        ? "${formatDate(invoice.date)} · Due ${formatDateShort(invoice.dueDate)}"
                        : formatDate(invoice.date),
                    style: TextStyle(fontSize: 12, color: p.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(formatMoney(invoice.total), style: AppTheme.display(size: 16, color: p.ink)),
            if (showActions)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShare != null)
                    IconButton(
                      tooltip: "Share PDF",
                      visualDensity: VisualDensity.compact,
                      onPressed: onShare,
                      icon: Icon(Icons.ios_share_rounded, size: 20, color: p.muted),
                    ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: "Edit invoice",
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_rounded, size: 20, color: p.muted),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
