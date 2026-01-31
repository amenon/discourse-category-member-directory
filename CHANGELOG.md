# Changelog

## [1.0.0] - 2026-01-31

Initial release.

### Features
- Member avatar grid on category pages
- Collapsed by default (1 row) with "View all" link to expand
- Expands to show up to 3 rows with pagination for more
- Auto-match category slugs to group names (enabled by default)
- Optional prefix/suffix for group naming conventions
- Manual category-to-group mapping for exceptions
- Responsive design for mobile and desktop
- Theme-aware styling using Discourse CSS variables

### Settings
- `auto_match_by_slug` - Auto-match enabled by default
- `group_slug_prefix` / `group_slug_suffix` - Optional naming patterns
- `category_group_mapping` - Manual overrides (format: `id:group|id:group`)
- `members_per_page` - Members per page (default: 20)
- `show_member_names` - Show names below avatars
- `card_title` - Card header text
- `show_member_count` - Show total in title
