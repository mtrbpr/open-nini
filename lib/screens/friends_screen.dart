import 'package:flutter/material.dart';

import '../nini_scope.dart';
import '../router.dart';
import '../widgets/account_widgets.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = NiniScope.of(context).account;
    return AccountBrowser(
      title: 'دوستان من',
      tabs: [
        AccountTabSpec(
          label: 'دوستان من',
          load: (offset) => api.friends(offset: offset),
          actions: (record) => [
            AccountButton(
              label: 'ارسال پیام',
              run: () async {
                openChat(context, name: record.title, avatarUrl: record.imageUrl, userPath: record.path);
              },
            ),
            if (record.id != null)
              AccountButton(
                label: 'لغو دوستی',
                confirm: 'دوستی لغو شود؟',
                run: () => api.deleteFriend(record.id!),
              ),
          ],
        ),
        AccountTabSpec(
          label: 'درخواست های دوستی',
          load: (offset) => api.friendRequests(sent: false, offset: offset),
          actions: (record) => [
            if (record.id != null) AccountButton(label: 'پذیرش', run: () => api.acceptFriend(record.id!)),
            if (record.id != null) AccountButton(label: 'رد کردن', run: () => api.rejectFriend(record.id!)),
          ],
        ),
        AccountTabSpec(
          label: 'درخواست های ارسالی',
          load: (offset) => api.friendRequests(sent: true, offset: offset),
          actions: (record) => [
            if (record.id != null)
              AccountButton(
                label: 'لغو',
                confirm: 'درخواست لغو شود؟',
                run: () => api.cancelFriend(record.id!),
              ),
          ],
        ),
      ],
    );
  }
}
