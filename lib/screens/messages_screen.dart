import 'package:flutter/material.dart';

import '../nini_scope.dart';
import '../router.dart';
import '../widgets/account_widgets.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = NiniScope.of(context).account;
    return AccountBrowser(
      title: 'پیام های من',
      action: TextButton(
        onPressed: () => openAccountPage(context, '/profile/conversation/create', title: 'پیام جدید'),
        child: const Text('پیام جدید'),
      ),
      tabs: [
        AccountTabSpec(
          label: 'پیام های دریافتی',
          load: (offset) => api.messages(sent: false, offset: offset),
          actions: (record) => [
            if (record.id != null)
              AccountButton(
                label: 'حذف',
                confirm: 'این پیام حذف شود؟',
                run: () => api.deleteMessage(record.id!),
              ),
          ],
        ),
        AccountTabSpec(
          label: 'پیام های ارسالی',
          load: (offset) => api.messages(sent: true, offset: offset),
          actions: (record) => [
            if (record.id != null)
              AccountButton(
                label: 'حذف',
                confirm: 'این پیام حذف شود؟',
                run: () => api.deleteMessage(record.id!),
              ),
          ],
        ),
      ],
    );
  }
}
