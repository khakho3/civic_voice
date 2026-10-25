# Password masking - Android review implementation

Owner prioritised this work on 25 October 2026. The Android app suppresses
Flutter's brief last-character reveal while a password field is hidden. Explicit
Show/Hide remains available. Owner confirms Android hidden typing is fixed;
other auth-flow/IME/password-manager checks and native iOS suppression remain
separate. The later web implementation is described under Remaining platform limits.

## Implementation and scope

Flutter's secure EditableText uses PlatformDispatcher.brieflyShowPassword. The
current SDK exposes no per-field switch. CivicVoiceApplication installs a
FlutterJNI factory during attachBaseContext, before providers/plugins can access
FlutterInjector. The ordinary loader, executor, Activity/engine ownership and
plugin registration remain in place.

PasswordMaskingFlutterJNI changes only brieflyShowPassword to false in outgoing
flutter/settings JSON. It retains all other settings, including configurationId,
font scale, brightness, clock format, spellcheck and unknown future fields. It
decodes a duplicate buffer, retains the caller's position and response ID, and
forwards other channels or invalid payloads normally. It never changes the
phone's global password setting or logs settings/password contents.

The five existing password inputs (Login, two Registration fields and two final
password fields shared by forgot/change/first-login flows) remain ordinary secure
TextFormFields with their real controller values, autofill hints, validation and
explicit Show/Hide. There are no fake password strings or per-keystroke focus or
input-type changes. Existing shared padlock icons remain.

This applies to engines constructed through the installed factory. The current
app uses one UI engine; it does not use FlutterEngineGroup/spawned UI engines.
Recheck this integration if adding spawned UI engines, another custom Application
or FlutterInjector factory, or upgrading Flutter. Do not replace this with a
partial settings message: Flutter still needs every ordinary engine setting.

## Verification

- Six widget contracts reproduce Android's baseline reveal, then check immediate
  masking across all five real fields when the platform preference is false.
  They cover Latin/digits/symbols/Unicode, replacement/deletion, secure input,
  autofill configuration, copy/cut protection with selected text, and Show/Hide.
  Widget preference overrides are test-only and do not prove Android integration.
- A separate offline, zero-permission Android profile probe uses the same JNI
  filter and Application implementation (package name is the only substitution).
  It checks the real platform preference, actual RenderEditable output 80 ms
  after each dummy-character insertion with an active input connection, native
  settings preservation and eight JSON/buffer cases. It uses no account/network.
- Before the policy, the API 36 emulator showed each of eight newly inserted
  characters. With the policy, all eight masked immediately while the OS reveal
  setting remained enabled. Secure-input/autofill configuration, explicit
  Show/Hide and default font/brightness/clock checks passed. Follow-up cold-start
  checks also pass with 1.3x text, dark mode and 24-hour time. Compare Android float font scale with
  a 0.000001 tolerance rather than exact floating-point equality.
- Actual password-manager filling, keyboard/IME interaction, accessibility and
  phone feel remain owner/device checks. A locked physical device is not a pass.
  Keep exact disposable-probe/device/build evidence in the private checklist.

Run flutter test test/password_masking_contract_test.dart, the full test suite
and flutter analyze. Build the isolated DEV artifact with verified DEV identity,
API and Firebase targets before installation. DEV's manifest change is limited
to the Application name; never copy the production manifest/configuration over
DEV. Preserve app data and the phone's system settings.

## Remaining platform limits

25 October owner update: Flutter Android hidden typing is confirmed fixed. Keep
other auth-flow/IME/password-manager/device checks separate. Web536ddf1 now adds
a local dot-only font to real password inputs, retaining native semantics and
Show/Hide; see web docs/WEB_PASSWORD_MASKING.md. Desktop Chromium/font checks
pass; direct mobile-browser echo remains pending after automatic approval review
blocked the Android Chrome test command without a detailed reason. Native iOS
embedding suppression remains unimplemented/unverified.

References: [Flutter preference](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/brieflyShowPassword.html),
[FlutterJNI](https://api.flutter.dev/javadoc/io/flutter/embedding/engine/FlutterJNI.html),
[native web password input](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/password).
