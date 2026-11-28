# QUBA — Complete Liquid Glass UI Transformation (Umar's brief, 2026-11-28)

Reference screenshot (design authority): ~/workspace/user/media_library/image/QUBA_Islamic_App_Glassmorphism_Home_Screen.png

You are a senior Flutter UI/UX engineer working directly inside my existing QUBA Islamic companion app project.

I have provided a reference screenshot. Your job is to make my actual application UI look as close as possible to that screenshot.

This is a real application, not a demo. You must modify the existing Flutter source code and preserve all existing functionality.

## PRIMARY OBJECTIVE

Transform QUBA into a premium, modern, Apple-inspired liquid-glass Islamic app.

The design must look like glass floating in water:

- Crystal-clear translucent surfaces
- Realistic frosted glass blur
- Bright white glass edges
- Soft emerald reflections
- Subtle mint gradients
- Beautiful floating shadows
- Smooth rounded cards
- Elegant typography
- Perfect alignment and spacing

The reference screenshot is the design authority. Do not invent a different design direction.

## 1. Background

Use a clean white background.

Add only extremely subtle mint-green ambient lighting behind the UI.

Do not add:
- Kaaba images
- Mosque photographs
- Quran photographs
- Large decorative illustrations
- Background image textures
- Unnecessary Islamic patterns

The background must remain white, clean, peaceful, and minimal.

The glass surfaces should create the visual interest.

## 2. Header

Redesign the QUBA header to match the reference:

- Premium QUBA logo
- Elegant QUBA wordmark
- Subtitle: Your Islamic Companion
- Floating circular glass settings button

Keep the logo and wordmark perfectly aligned.

Use a translucent glass capsule with a fine white border and soft green shadow.

## 3. Next Prayer card

Create a large floating glass card.

Left side:
- Small label: Next Prayer
- Large prayer name
- Live countdown timer

Right side:
- Large circular countdown indicator
- Emerald progress ring
- Translucent glass center

Use actual prayer data and actual countdown calculations from the existing application.

Do not use static countdown values.

## 4. Prayer Times card

Create a large premium frosted-glass panel.

Header:
- Prayer Times
- View All action

Rows:
- Fajr
- Sunrise
- Dhuhr
- Asr
- Maghrib
- Isha

Every row must have:
- Consistent icon size
- Consistent left alignment
- Prayer name
- Perfectly right-aligned prayer time
- Equal vertical spacing

Highlight the next prayer using a soft mint-green glass pill.

The active row must look integrated into the panel, not like a separate flat button.

Remove unnecessary visual clutter.

## 5. Continue Reading card

Create a clean floating glass card.

Match the reference layout:

- Minimal left visual area
- Thin emerald vertical divider
- Continue Reading label
- Current Surah name
- Current verse
- Reading progress bar
- Percentage completed
- Circular glass continue button

Do not add a large Quran picture.

Use actual Quran reading progress from the existing application.

## 6. Bottom navigation

Create a single floating liquid-glass navigation capsule.

Four tabs:

- Home
- Quran
- Extras
- Settings

Requirements:

- Equal width for all four tabs
- Consistent icon size
- Icon above label
- Soft emerald active indicator
- Subtle mint active background
- Thin separators
- Fine white glass border
- Floating shadow

The navigation must remain fixed at the bottom of the screen.

It must not scroll with the page.

## 7. Liquid glass material

Create or improve a reusable LiquidGlass widget.

Use Flutter's:

- ClipRRect
- BackdropFilter
- ImageFilter.blur
- Layered gradients
- BoxDecoration
- Border
- BoxShadow
- Stack
- Positioned

The glass should have multiple visual layers:

1. Translucent white/mint base
2. Real background blur
3. Fine bright white border
4. Top-edge specular highlight
5. Subtle emerald reflection
6. Soft ambient shadow

Suggested starting values:

Main card radius: 30–34
Glass blur: 20–28
Border width: 1–1.5
Background opacity: approximately 30–55%
Shadow blur: 25–35
Shadow opacity: approximately 8–15%

These values are starting points. Adjust them to match the reference screenshot.

Do not make the cards look foggy, opaque, or excessively green.

## 8. Design consistency

Use one consistent design system throughout the app.

Suggested colors:

Background: #FDFEFD
Primary emerald: #0B5F3B
Deep emerald: #064A32
Mint: #DDF4E5
Main text: #17211B
Secondary text: #77786F
Glass border: translucent white

Use consistent:
- Card radius
- Horizontal margins
- Vertical spacing
- Typography sizes
- Icon dimensions
- Button dimensions
- Glass opacity
- Shadow softness

Avoid uneven card edges, inconsistent padding, oversized icons, or cramped text.

## 9. IMPORTANT: Existing project instructions

First inspect the entire existing Flutter project.

Reuse and improve the existing components where possible, including:

- GlassCard
- QubaHeader
- QubaBackground
- PrayerScheduleCard
- Continue Reading card
- Glass bottom navigation

Do not create duplicate components if the existing ones can be improved.

Do not rebuild the application from scratch.

Do not replace the application with a screenshot.

Do not create a static design mockup.

Do not remove existing features.

Preserve:
- Prayer calculations
- Prayer reminders
- Quran reading
- Quran progress
- Navigation
- Settings
- Localization
- English, Dari, and Pashto
- Right-to-left layout
- Dark mode
- Existing data and state management

Keep all buttons and navigation functional.

## 10. Performance

Liquid glass must look premium without making the application slow.

Avoid excessive nested BackdropFilters.

Use blur only on major glass surfaces.

Use lightweight translucent surfaces for list rows.

Avoid unnecessary rebuilds and expensive animations.

Ensure the UI remains smooth on normal Android devices.

## 11. Responsive layout

The design must work on different screen sizes.

Do not hardcode the entire screen to one screenshot resolution.

Use:
- Expanded
- Flexible
- LayoutBuilder
- SafeArea
- Responsive spacing
- Proper scrolling

Prevent overflow in English, Dari, and Pashto.

Keep the bottom navigation fixed.

## 12. Execution requirements

Do not stop after writing a plan.

Actually modify the existing source code.

Work through the following stages:

Stage 1: Inspect the project and identify the existing home-screen components.

Stage 2: Improve the reusable glass material and background.

Stage 3: Redesign the header and Next Prayer card.

Stage 4: Redesign and align the Prayer Times panel.

Stage 5: Redesign the Continue Reading card.

Stage 6: Redesign the floating bottom navigation.

Stage 7: Check the complete screen and refine spacing, typography, glass effects, and alignment.

Stage 8: Run Flutter analysis and tests if the Flutter SDK is available.

Fix any errors caused by your changes.

Stage 9: Build or verify the project if possible.

Stage 10: Save the complete updated project and provide the finished project ZIP.

Do not claim the project is complete unless the changes have actually been applied and verified.

## FINAL RESULT

I want QUBA to look like the exact liquid-glass design in my reference screenshot.

It should feel like a premium commercial Islamic application, with beautiful floating glass cards, emerald reflections, crystal-clear surfaces, elegant typography, and perfectly aligned content.

Make the real application look like the reference.

Do not disappoint me with a generic redesign.
