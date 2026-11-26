# QUBA — Premium Liquid Glass UI Redesign (Umar's brief, 2026-11-26)

You are a senior UI/UX designer and expert frontend/mobile application developer.

I am building QUBA — Your Islamic Companion, an Islamic app. I have provided a reference screenshot showing the exact visual style I want.

Your task is to redesign my existing app UI to closely match the reference screenshot.

1. Main design direction

Recreate the visual style of the reference image:

- Premium Apple-inspired liquid glass UI
- Transparent, translucent, and frosted glass surfaces
- Emerald green and deep forest green as primary colors
- Pure white and very light mint backgrounds
- Soft realistic reflections and refractions
- Smooth rounded corners
- Floating glass panels with subtle depth
- Beautiful soft shadows
- Minimal, elegant Islamic atmosphere
- Premium, modern, clean, and sophisticated

The interface should feel like glass floating in water.

Do not create a generic Islamic app design. Follow the reference screenshot as closely as possible.

2. Header

Create a beautiful floating glass header containing:

- QUBA logo with a green mosque silhouette and crescent
- Large elegant QUBA wordmark
- Subtitle: "Your Islamic Companion"
- Floating circular glass settings button on the right

Use balanced spacing and perfectly aligned elements.

3. Next Prayer card

Create a large premium liquid-glass card displaying:

- Small emerald pill: "Next Prayer"
- Large prayer name, such as "Maghrib"
- Countdown timer
- Circular countdown indicator on the right

The circular indicator should have a green progress ring with a translucent glass center.

Use a clear hierarchy: prayer name is the largest element, countdown is smaller, and the label is subtle.

4. Prayer Times card

Create a large translucent glass panel with:

- Header: "Prayer Times"
- "View All" action with arrow
- Six aligned rows: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
- Beautiful minimal icons
- Prayer names aligned consistently on the left
- Prayer times aligned perfectly on the right

Highlight the currently active or upcoming prayer with a soft mint-green glass pill.

Keep the rows evenly spaced, with subtle dividers and consistent icon sizes.

5. Continue Reading card

Create a floating glass card showing:

- "Continue Reading"
- Current Surah name
- Current verse number
- Reading progress bar
- Percentage completed
- Circular glass button to continue reading

Use elegant typography and clean alignment.

6. Bottom navigation

Create a floating liquid-glass navigation bar with four tabs:

- Home
- Quran
- Extras
- Settings

Each tab should have a clear icon and label.

The active tab should have a soft emerald glass highlight and a subtle green underline.

The navigation bar should appear to float above the background with realistic glass reflections.

7. Liquid glass implementation

Do not simply use transparent white cards.

Implement convincing liquid-glass surfaces using:

- Backdrop blur
- Semi-transparent white or mint backgrounds
- Fine translucent borders
- Inner highlights
- Soft ambient shadows
- Subtle green reflections
- Layered gradients
- Light refraction-inspired edge effects

Use CSS backdrop-filter where supported.

Example visual direction:

background: rgba(255, 255, 255, 0.28);
backdrop-filter: blur(24px) saturate(180%);
border: 1px solid rgba(255, 255, 255, 0.75);
box-shadow: 0 12px 35px rgba(20, 100, 65, 0.12);

Adapt the implementation to the existing technology stack.

8. Background

Use a clean, very light white or mint background.

Add extremely subtle green ambient lighting and soft gradients.

The background must remain simple and uncluttered.

Do not add large mosque pictures, Kaaba pictures, photographs, or distracting illustrations.

The glass UI itself should be the main visual attraction.

9. Typography and alignment

Use a modern, clean sans-serif font.

Maintain:

- Consistent horizontal margins
- Perfectly aligned card edges
- Consistent corner radii
- Balanced vertical spacing
- Clear typography hierarchy
- Proper icon sizing
- Equal padding inside cards

Avoid oversized text, uneven spacing, cramped rows, and inconsistent card heights.

10. Important development instructions

This is an existing application.

Do not rebuild the entire app from scratch.

First inspect the existing project structure, framework, components, styling system, and current functionality.

Then redesign the UI while preserving the existing application architecture.

Do not remove or break any existing features.

All buttons, navigation tabs, prayer calculations, countdowns, Quran progress, settings, and other existing functions must continue working.

Do not use fake data if real application data already exists.

Do not replace functional components with static screenshots.

Do not create a design-only mockup.

Implement the actual UI in the existing codebase.

Final objective

The finished QUBA interface should look extremely close to the provided reference screenshot:

A premium Islamic companion app with emerald green accents, realistic liquid-glass cards, elegant typography, perfectly aligned prayer information, and a beautiful floating bottom navigation bar.

Make it look like a polished commercial application ready for release.
