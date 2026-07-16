# Project Challenges

Notable platform-specific issues encountered during development, documented as they were solved.

## Android's native splash screen isn't something you draw — it's OS behavior you configure

While polishing the launch experience, we discovered the app briefly showed *two* different splash-like screens in sequence: a plain icon on a solid background, then our actual Flutter-built splash screen with the app name and tagline. This wasn't intentional — it turned out to be two entirely separate systems stacking on top of each other, which isn't obvious if you've never hit it before:

1. **The native OS splash.** Every Android app shows a brief system-drawn screen the instant it's tapped, before the Flutter engine has even finished loading — there's no way to skip this outright, since it's what covers the gap between "user tapped the icon" and "the app's own UI can render anything." It's controlled by Android resource files (`styles.xml`, `launch_background.xml`), not Flutter code.
2. **Our own Flutter `SplashScreen` widget**, which rendered *after* the native splash handed off, showing the CivicVoice logo, title, and a "Checking secure session" loading state for a couple of seconds before moving on.

Because our native splash configuration hadn't been customized, Android was falling back to its own default behavior: auto-generating a splash icon from the app's launcher icon. Once we noticed that, the double-splash made sense — the app was showing branding twice, back to back.

**The fix** was to configure the native splash properly (via the `flutter_native_splash` package) to show our actual logo and matching background color, and then remove the redundant Flutter splash screen entirely — letting the native splash hand off directly to the Welcome screen. One splash experience instead of two.

## Android 12+ forces splash icons into a circular mask — and it's not optional

Once the native splash was showing our real logo, a new problem appeared: our logo — a speech-bubble shape with a small tail — was getting clipped by a hard circular crop, and there was no visible background behind it, so the tail disappeared into the surrounding screen color.

This turned out to be a genuine platform constraint, not a bug in our config: starting with Android 12 (API 31), the OS's Splash Screen API *always* displays the splash icon inside a fixed circular mask, for every app, with no way to request a different shape for that specific element. Apps that don't appear to have this circular treatment (e.g. X/Twitter) have simply designed their logo asset to work well within that constraint, or built their splash entirely outside the icon-API path — the constraint itself doesn't go away.

**The fix** had two parts:
1. Set an explicit background color behind the icon (`icon_background_color` in the Android 12 splash config) so the logo has a visible surface to sit on, rather than floating directly on the splash's outer background.
2. Rebuild the logo asset itself with generous transparent padding around it (a 1152×1152 canvas with the mark scaled to ~700px, centered) — since Android 12 only shows roughly the inner ~66% of the provided image inside its circular crop, the original tightly-cropped logo asset needed room to breathe so nothing meaningful got cut off.

## Takeaway

Both issues share a root cause: assuming "the splash screen" is something you build entirely in Dart/Flutter, when in reality a meaningful part of it is OS-level configuration with its own rules (some configurable, some genuinely fixed platform behavior). Worth checking native platform docs early for anything that renders before the Flutter engine has control, rather than assuming Flutter code is the whole picture.
