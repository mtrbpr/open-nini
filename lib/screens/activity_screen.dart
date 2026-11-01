import 'package:flutter/material.dart';

import '../data/account_api.dart';
import '../nini_scope.dart';
import '../router.dart';
import '../widgets/account_widgets.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({required this.kind, super.key});

  final String kind;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  var _order = 0;

  @override
  Widget build(BuildContext context) {
    final api = NiniScope.of(context).account;
    final spec = _spec(widget.kind, api);
    return AccountBrowser(
      key: ValueKey('${widget.kind}-$_order'),
      title: spec.title,
      action: spec.uploadPath == null
          ? null
          : TextButton(
              onPressed: () => openAccountPage(context, spec.uploadPath!, title: spec.uploadTitle),
              child: Text(spec.uploadTitle ?? 'آپلود'),
            ),
      header: spec.ordered
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('جدیدترین'),
                    selected: _order == 0,
                    onSelected: (selected) {
                      if (selected) setState(() => _order = 0);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('پست جدید'),
                    selected: _order == 1,
                    onSelected: (selected) {
                      if (selected) setState(() => _order = 1);
                    },
                  ),
                ],
              ),
            )
          : null,
      tabs: spec.tabs,
    );
  }

  _ActivitySpec _spec(String kind, AccountApi api) {
    switch (kind) {
      case 'clinic':
        return _ActivitySpec(
          title: 'کلینیک من',
          tabs: [
            _questions(api, 'سوالات پاسخ داده شده', '/profile/clinic/GetAnsweredQuestions'),
            _questions(api, 'در انتظار پاسخ', '/profile/clinic/GetWaitingToAnswerQuestions'),
            AccountTabSpec(
              label: 'سوالات ذخیره شده',
              load: (offset) => api.questions('/profile/clinic/GetFavoriteQuestions', offset: offset),
              actions: (record) => [
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این سوال از ذخیره‌شده‌ها حذف شود؟',
                    run: () => api.removeFavoriteQuestion(record.id!),
                  ),
              ],
            ),
            AccountTabSpec(
              label: 'تجربیات من',
              load: (offset) => api.comments('/profile/clinic/GetComments', offset: offset),
              actions: (record) => const [],
            ),
          ],
        );
      case 'photo':
        return _ActivitySpec(
          title: 'عکس های من',
          uploadPath: '/profile/photo/upload',
          uploadTitle: 'آپلود عکس',
          tabs: [
            AccountTabSpec(
              label: 'عکس های من',
              load: (offset) => api.photos('/profile/photo/GetPhotos', offset: offset),
              actions: (record) => [
                if (record.editPath != null)
                  AccountButton(
                    label: 'ویرایش',
                    run: () async => openAccountPage(context, record.editPath!, title: 'ویرایش'),
                  ),
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این عکس حذف شود؟',
                    run: () => api.removePhoto(record.id!),
                  ),
              ],
            ),
            AccountTabSpec(
              label: 'عکس های ذخیره شده',
              load: (offset) => api.photos('/profile/photo/GetFavoritePhotos', offset: offset),
              actions: (record) => [
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این عکس از ذخیره‌شده‌ها حذف شود؟',
                    run: () => api.removeFavoritePhoto(record.id!),
                  ),
              ],
            ),
            AccountTabSpec(
              label: 'نظرات من',
              load: (offset) => api.comments('/profile/photo/GetComments', offset: offset),
              actions: (record) => const [],
            ),
          ],
        );
      case 'video':
        return _ActivitySpec(
          title: 'ویدیوهای من',
          uploadPath: '/profile/video/upload',
          uploadTitle: 'آپلود ویدیو',
          tabs: [
            AccountTabSpec(
              label: 'ویدئوهای من',
              load: (offset) => api.videos('/profile/video/GetVideos', offset: offset),
              actions: (record) => [
                if (record.editPath != null)
                  AccountButton(
                    label: 'ویرایش',
                    run: () async => openAccountPage(context, record.editPath!, title: 'ویرایش'),
                  ),
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این ویدیو حذف شود؟',
                    run: () => api.removeVideo(record.id!),
                  ),
              ],
            ),
            AccountTabSpec(
              label: 'ویدئوهای ذخیره شده',
              load: (offset) => api.videos('/profile/video/GetFavoriteVideos', offset: offset),
              actions: (record) => [
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این ویدیو از ذخیره‌شده‌ها حذف شود؟',
                    run: () => api.removeFavoriteVideo(record.id!),
                  ),
              ],
            ),
            AccountTabSpec(
              label: 'نظرات من',
              load: (offset) => api.comments('/profile/video/GetComments', offset: offset),
              actions: (record) => const [],
            ),
          ],
        );
      default:
        return _ActivitySpec(
          title: 'تبادل نظر من',
          ordered: true,
          tabs: [
            AccountTabSpec(
              label: 'تاپیک های من',
              load: (offset) => api.topics('/profile/forumApi/GetMyTopics', offset: offset, orderBy: _order),
              actions: (record) => [
                if (record.id != null && record.open != false)
                  AccountButton(label: 'قفل کردن', run: () => api.lockTopic(record.id!, unlock: false)),
                if (record.id != null && record.open != true)
                  AccountButton(label: 'باز کردن', run: () => api.lockTopic(record.id!, unlock: true)),
              ],
            ),
            AccountTabSpec(
              label: 'شرکت کردم',
              load: (offset) => api.topics('/profile/forumApi/GetParticipateTopics', offset: offset, orderBy: _order),
              actions: (record) => const [],
            ),
            AccountTabSpec(
              label: 'تاپیک های ذخیره شده',
              load: (offset) => api.topics('/profile/forumApi/GetFavoriteTopics', offset: offset, orderBy: _order),
              actions: (record) => [
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این تاپیک از ذخیره‌شده‌ها حذف شود؟',
                    run: () => api.removeFavoriteTopic(record.id!),
                  ),
              ],
            ),
            AccountTabSpec(
              label: 'پست های من',
              load: (offset) => api.posts('/profile/forumApi/GetMyPosts', offset: offset),
              actions: (record) => const [],
            ),
            AccountTabSpec(
              label: 'پست های ذخیره شده',
              load: (offset) => api.posts('/profile/forumApi/GetFavoritePosts', offset: offset),
              actions: (record) => [
                if (record.id != null)
                  AccountButton(
                    label: 'حذف',
                    confirm: 'این پست از ذخیره‌شده‌ها حذف شود؟',
                    run: () => api.removeFavoritePost(record.id!),
                  ),
              ],
            ),
          ],
        );
    }
  }

  AccountTabSpec _questions(AccountApi api, String label, String path) {
    return AccountTabSpec(
      label: label,
      load: (offset) => api.questions(path, offset: offset),
      actions: (record) => const [],
    );
  }
}

class _ActivitySpec {
  const _ActivitySpec({
    required this.title,
    required this.tabs,
    this.uploadPath,
    this.uploadTitle,
    this.ordered = false,
  });

  final String title;
  final List<AccountTabSpec> tabs;
  final String? uploadPath;
  final String? uploadTitle;
  final bool ordered;
}
