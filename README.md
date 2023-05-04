# Grouped Infinite List

[![Grouped Infinite List][pub_badge]][pub_link] [![License: MIT][license_badge]][license_link]

Grouped Infinite ListView with items that can be scrolled infinitely in both directions. This widget use [CustomScrollView][custom_scroll_view_link] with two [SliverList][sliver_list_link] to achive this.

This package inspired by [grouped_list][grouped_list_link] package.

## Installation 💻

**❗ In order to start using Grouped Infinite List you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Add `grouped_infinite_list` to your `pubspec.yaml`:

```yaml
dependencies:
  grouped_infinite_list:
```

Install it:

```sh
flutter packages get
```

### Parameters:

| Parameter                    | Description                                                                                                                | Required | Default         |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------- | --------------- |
| `positiveItems`              | List of items that will be displayed in the positive direction                                                             | required | -               |
| `negativeItems`              | List of items that will be displayed in the negative direction                                                             | no       | emptyList       |
| `groupBy`                    | Function to determine which group an item belongs to                                                                       | required | -               |
| `itemBuilder`                | Function to build a widget for each item in the list.                                                                      | required | -               |
| `groupSeparatorBuilder`      | Function to build a group header separator in the list.                                                                    | required | -               |
| `groupSeparatorPadding`      | Padding for the group header separator in the list.                                                                        | no       | EdgeInsets.zero |
| `useStickyGroupSeparators`   | Whether to use sticky group separators. Header will stick on top.                                                          | no       | false           |
| `separator`                  | Widget that will be displayed between items                                                                                | no       | -               |
| `groupComparator`            | Function to sort the list of groups                                                                                        | no       | -               |
| `itemComparator`             | Function to sort the items inside a group                                                                                  | no       | -               |
| `stickyHeaderPositionOffset` | Offset from the top of the screen at which sticky headers should stick. Usefull if you need your list scroll behind appBar | no       | 0               |

**Also you can use Parameters from [CustomScrollView][custom_scroll_view_link]**

<!-- Links -->

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[license_link]: https://opensource.org/licenses/MIT
[grouped_list_link]: https://pub.dev/packages/grouped_list
[pub_badge]: https://img.shields.io/pub/v/grouped_infinite_list.svg?style=flat-square
[pub_link]: https://pub.dev/packages/grouped_infinite_list
[custom_scroll_view_link]: https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html
[sliver_list_link]: https://api.flutter.dev/flutter/widgets/SliverList-class.html
