import 'package:flutter/material.dart';

IconData discussionIcon(String? iconClass) {
  switch (iconClass) {
    case 'iconbirth':
    case 'iconpregnancy2':
      return Icons.pregnant_woman;
    case 'iconmarriage':
      return Icons.favorite;
    case 'iconnewborn':
      return Icons.crib;
    case 'icontoddler':
      return Icons.child_care;
    case 'iconchild2':
      return Icons.escalator_warning;
    case 'iconparent':
    case 'iconfamily':
      return Icons.family_restroom;
    case 'iconring':
      return Icons.diamond;
    case 'iconbirthday':
      return Icons.cake;
    case 'iconlocation-fill':
      return Icons.location_on;
    case 'iconstore2':
      return Icons.storefront;
    case 'iconculture':
      return Icons.palette;
    case 'iconreligion':
      return Icons.mosque;
    case 'iconangel-fill':
      return Icons.auto_awesome;
    case 'iconlife':
      return Icons.spa;
    case 'iconconsultant':
      return Icons.support_agent;
    case 'iconmanager':
      return Icons.admin_panel_settings;
    case 'iconother':
      return Icons.more_horiz;
    default:
      return Icons.forum;
  }
}
