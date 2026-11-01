# Android notification mark - 1 November 2026

Owner confirms the existing monochrome notification status-bar icon works and
requests a tiny enlargement. This accepts the existing function/identity, not
the new size or unrelated haptics/platform checks.

The installed mark is the committed Android vector
`android/app/src/main/res/drawable/ic_stat_civic_voice.xml`, selected by the FCM
default-notification-icon manifest metadata. It is separate from the themed
launcher `ic_launcher_monochrome` resources.

The original checkout's untracked `assets/branding/notification-monochrome.svg`
was unused imported artwork. It is now preserved verbatim in this working branch
as reference artwork, including its existing provenance metadata. It does not
replace the accepted simplified Android vector or enter the Flutter asset bundle.
Original file: 46,596 bytes; SHA256
`b22e9d54333cf170957732b3576657105bb367711b74f5f36748fc27a4cd857b`.
The original checkout/file remains untouched on its older branch; no promotion
is implied by preserving the reference here.

Requested next adjustment: scale only the existing notification vector artwork
by 1.06 about the 24dp viewport's centre. Keep the exact path/cutouts, white alpha
mask, resource ID, notification tint and launcher resources. Compile/render and
verify the isolated DEV artifact before installation. New-size owner acceptance
remains pending. After this bounded owner-requested change, resume queue07.
