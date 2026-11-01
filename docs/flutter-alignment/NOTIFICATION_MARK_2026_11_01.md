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

Implemented in 82384fb: only the existing notification vector artwork scales by
1.06 about the 24dp viewport centre. Exact path/cutouts, white alpha mask, resource
ID and notification tint are preserved. Source artwork preservation is 6c09f9b.

Verification: AAPT2 compiles the resource; native-vector renders at 24/36/48/72/96/
768px remain unclipped. Before/after geometry preserves the exact path. The final
profile APK contains the compiled 1.06 scales, excludes the unbundled reference
SVG and retains byte-identical launcher resources. All 76 reviewed-source hashes
and 14 protected DEV configuration hashes match; DEV package/label/signing/Firebase/
API and actual local service/phone/Maps restriction checks pass. Existing 1,985
Flutter tests/analyzer cover the unchanged Dart runtime; they were not rerun for
this Android-resource-only change.

Verified DEV 82384fb is wirelessly replace-installed/launched on the Pixel, with
data retained, installed digest matched and current report-draft/intent values
unchanged. Private ledger: web .tmp/dev-notification-size-preflight.json; renders:
notification-mark-render-proof.json / notification-mark-size-comparison.png.
Original SVG in the older checkout remains unchanged. New-size **owner acceptance
is pending**; the prior mark's function remains owner-confirmed. Queue 07 resumes.
No API/web runtime change, merge, promotion or deployment.
