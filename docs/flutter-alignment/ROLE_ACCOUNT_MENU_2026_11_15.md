# Role account menus · 15 November 2026

The owner's role/navigation contract is applied through the existing account
menu and role scaffolds:

- Maintenance Home and Tasks offer Log Out only in their account menu. Profile
  remains in primary navigation. Its Profile header omits the menu.
- Municipal, Ministry and Assembly Admin retain Profile and Log Out in their
  account menus. Their verified route callbacks continue to open Profile.
- All Profile screens retain in-page logout. Assembly Admin's Profile omits
  the account menu even in a host that does not provide a Back callback.
- Native popup placement, motion, logout confirmation, cancellation, duplicate
  submission protection and session teardown remain in the shared components.

All 2,444 Flutter tests and analyzer passed. Twenty focused checks cover both
themes, 320px menus at 2× text, Profile navigation, Maintenance's primary Profile
entry, cancellation, confirmed shared logout and Profile-page logout/menu rules.
The actual Profile bodies were checked at normal text for this menu change.

A pre-existing 320px/2× Profile preference-row trailing-width failure was found
while scrolling the unchanged Profile bodies. It reproduced before these menu
changes and remains a separately recorded layout follow-up. Do not claim a
complete large-text Profile-body acceptance from these menu checks.

DEV build/install, agent phone observations and owner acceptance are tracked
separately in Web `docs/CURRENT_STATUS.md` and its private artifact ledger. This
source checkpoint does not claim a new phone installation or owner acceptance.
No API permissions, role/account data, production settings or release branch
promotion changed.
