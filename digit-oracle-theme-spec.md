# Digit Oracle — Theme Specification

## Overview

Digit Oracle is an iOS app that scans the user's photos for occurrences of numbers they choose to track. The app presents findings in the voice of an ancient, all-knowing oracle delivering dramatic prophecies — the more matches found in a single photo, the more dramatic the delivery. The tone is tongue-in-cheek mystical, nerdy, and funny. The humor comes from the contrast between the gravitas of the oracle's delivery and the mundanity of what it's actually reading (gas receipts, speed limit signs, price tags).

---

## App Name

**Digit Oracle**

---

## Color Palette

The palette is dark, moody, and mystical — designed to evoke an ancient oracle's chamber lit by candlelight and gold.

### Primary Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Background Primary | Deep Black | `#0D0B14` | Main app background |
| Background Secondary | Dark Purple-Black | `#1A1525` | Cards, panels, secondary surfaces |
| Background Tertiary | Muted Dark Purple | `#241E33` | Input fields, subtle elevation |

### Accent Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Gold Primary | Rich Gold | `#C9A84C` | Primary accent, headings, important elements |
| Gold Light | Pale Gold | `#E8D48B` | Highlights, hover states, subtle emphasis |
| Gold Dark | Deep Antique Gold | `#8B7332` | Borders, dividers, muted accents |

### Supporting Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Purple Accent | Mystic Purple | `#6B3FA0` | Subtle glows, gradients, secondary accent |
| Purple Light | Ethereal Lavender | `#9B7FCC` | Subtle text highlights, secondary info |
| Text Primary | Warm Off-White | `#E8E0D0` | Body text, primary readable text |
| Text Secondary | Muted Parchment | `#9E9589` | Secondary/supporting text |
| Text Dimmed | Faded Stone | `#6B6560` | Placeholder text, disabled states |
| Success | Emerald Glow | `#4A9E6B` | Positive feedback |
| Error | Blood Ruby | `#9E3B3B` | Errors, destructive actions |

### Gradient Definitions

- **Oracle Glow:** Linear gradient from `#1A1525` to `#241E33` with a subtle `#6B3FA0` radial center — use behind oracle text reveals
- **Gold Shimmer:** Linear gradient from `#8B7332` through `#C9A84C` to `#E8D48B` — use sparingly for tier borders and ornamental lines
- **Void Fade:** Linear gradient from `#0D0B14` at 100% opacity to `#0D0B14` at 0% opacity — use for content fade edges

---

## Typography

The typography should feel ancient and mystical — like inscriptions on a temple wall — while remaining legible on mobile screens.

### Font Recommendations (iOS Available)

| Role | Font | Fallback | Weight |
|------|------|----------|--------|
| Oracle Prophecy Text | Custom serif (see note below) | Georgia | Bold / Bold Italic |
| Headings / Titles | Custom serif | Georgia | Semibold |
| Body Text | System serif or a clean serif | Palatino | Regular |
| UI Labels / Buttons | System default (SF Pro) | — | Medium |
| Numbers (sacred display) | Custom display serif | Didot | Bold |

### Font Style Notes

- **Oracle prophecy text** should feel like it was carved into stone or written on ancient parchment. Consider importing a custom font such as **Cinzel**, **Cormorant Garamond**, or **Trajan Pro** via the app bundle. Cinzel is recommended for the best balance of mystical gravitas and mobile legibility.
- **Sacred number display** (when showing the user's tracked number) should use a distinctive, elegant serif at large scale — make it feel like the number itself is an artifact.
- **UI labels and buttons** should use the iOS system font (SF Pro) for clarity and platform consistency. The mystical fonts are reserved for content and personality, not navigation.

### Text Sizing

| Element | Size | Line Height |
|---------|------|-------------|
| Oracle prophecy text | 20–24pt | 1.4 |
| Screen titles | 28–32pt | 1.2 |
| Body text | 16pt | 1.5 |
| UI labels / buttons | 15–17pt | 1.3 |
| Sacred number (large display) | 48–72pt | 1.0 |
| Caption / metadata | 13pt | 1.4 |

---

## Rarity Tier System

When the app finds the user's sacred number in a photo, the result is categorized by how many times the number appears in that single photo.

### Tier Definitions

| Tier | Matches | Color Accent | Border Style | Text Style |
|------|---------|-------------|-------------|------------|
| **Common** | 1 | `#8B7332` (Dark Gold) | Thin single line | Standard serif, normal weight |
| **Uncommon** | 2 | `#C9A84C` (Rich Gold) | Slightly thicker line | Serif, slightly larger |
| **Rare** | 3 | `#E8D48B` (Pale Gold) | Double line border | Serif bold, subtle outer glow |
| **Epic** | 4 | `#E8D48B` with `#6B3FA0` purple undertone | Ornate border with corner details | Serif bold italic, soft gold glow behind text |
| **Legendary** | 5+ | Full **Gold Shimmer** gradient | Most ornate border, decorative corner flourishes | Largest serif bold italic, rich ambient glow, text feels illuminated |

### Visual Escalation Guidelines

- **Subtle and elegant, never flashy.** No screen shake, no particle effects, no animations that feel like a mobile game.
- Escalation should feel like going from a simple clay tablet to an illuminated manuscript.
- **Common:** Clean, minimal. A simple gold line frames the result. The text is understated.
- **Uncommon:** The gold warms slightly. The border is a touch more substantial. Text carries a bit more weight.
- **Rare:** The border doubles. A very faint, soft glow appears around the text — like candlelight hitting gold leaf.
- **Epic:** Corner ornaments appear on the border (simple geometric or angular flourishes — not overly decorative). The purple accent enters as a subtle background shift. Text is bold italic.
- **Legendary:** The full ornate treatment. The border has the richest detail. The gold shimmer gradient is used. The text appears illuminated — as if light is emanating softly from behind the letters. This is the ceiling — it's refined, not loud.

### Tier Label Display

Each tier should display its name alongside the result. Use these labels:

- Common: **"A Whisper"**
- Uncommon: **"A Sign"**
- Rare: **"A Vision"**
- Epic: **"A Revelation"**
- Legendary: **"A Prophecy Fulfilled"**

---

## Oracle Text / Copy

The app speaks entirely in the voice of an ancient oracle. The oracle is dramatic, all-knowing, and completely serious — the humor comes from the audience knowing the oracle is reading a photo of a grocery receipt.

### Copy Principles

1. **Always in character.** The oracle never breaks the fourth wall. It never says "photo" or "image" — it says "vision," "sight," "revelation," or "the ether."
2. **Scales with rarity.** Common finds are brief and understated. Legendary finds are full dramatic proclamations.
3. **Uses archaic but readable language.** Thee/thy/thou sparingly. "Hath," "doth," "behold," "hearken" are welcome. Avoid making it unreadable.
4. **References the number as sacred.** The user's tracked number is always treated with reverence: "thy sacred number," "the chosen digits," "the foretold sequence."
5. **Never references the mundane source directly.** The oracle doesn't know what a receipt is. It sees only visions and signs.

### Example Oracle Text by Tier

**Common (1 match):**
- "The digits stir. Thy sacred number hath surfaced in the mortal realm."
- "A faint echo of the foretold number ripples through the ether."
- "The Oracle perceives thy number, quiet but present, in this vision."
- "Thy sacred digits make themselves known — briefly, but unmistakably."

**Uncommon (2 matches):**
- "Twice thy sacred number reveals itself. The pattern deepens."
- "The Oracle's eye widens. Thy chosen digits appear not once, but twice in this vision."
- "A coincidence? The Oracle thinks not. Thy number speaks with growing conviction."
- "Two sightings in a single vision. The threads of fate grow taut."

**Rare (3 matches):**
- "Thrice! The sacred number blazes across this vision. The Oracle trembles with knowing."
- "Three times thy number hath emerged. Such frequency is no accident — it is decree."
- "The veil thins. Thy foretold digits appear in triplicate. Attend to this omen."
- "A rare convergence. The Oracle hath not witnessed such a trinity of signs in many moons."

**Epic (4 matches):**
- "Four manifestations of thy sacred number in a single vision. The Oracle must steady itself."
- "Hearken well — thy chosen digits resound four times. The cosmos speaks with great urgency."
- "The ancient numerals align with fearsome precision. Four instances. The Oracle is shaken."
- "This vision pulses with thy sacred number. Four times it burns through the veil. Destiny draws near."

**Legendary (5+ matches):**
- "BEHOLD. Thy sacred number hath erupted across this vision [X] times. The Oracle falls to its knees. The prophecy is fulfilled."
- "The heavens themselves part. [X] manifestations of thy foretold number in a single vision. In all the Oracle's ages, such a sign hath never been witnessed."
- "ALL TREMBLE BEFORE THIS REVELATION. Thy sacred digits appear [X] times. The very fabric of the mortal realm bends to deliver this message unto thee."
- "The Oracle weeps with awe. [X] times — [X] TIMES — thy number blazes forth. This is not a sign. This is a DECREE from the ancient ones."

> **Implementation note:** `[X]` should be replaced with the actual match count. For Legendary tier, have the app randomly select from the pool of text options, or cycle through them so the user doesn't see the same message repeatedly.

---

## Onboarding Flow

The onboarding should feel like a mystical ritual — the oracle is awakening and bonding with the user by learning their sacred number.

### Screen 1: The Awakening

- **Background:** Solid `#0D0B14` black, transitioning with a slow, subtle fade to reveal the Oracle Glow gradient
- **Text (centered, gold, large serif):**
  > "The Oracle awakens."
- **Subtext (off-white, smaller):**
  > "It senses a seeker of hidden truths."
- **Action:** Single "Continue" or "Approach the Oracle" button in gold outline

### Screen 2: The Explanation

- **Text:**
  > "The Oracle possesses the sight to peer into thy captured visions and reveal the numbers hidden within."
- **Subtext:**
  > "Grant the Oracle access to thy visions, and it shall seek the sacred digits thou dost revere."
- **Note:** This screen should precede or coincide with the iOS photo library permission request. Frame the permission as part of the ritual.

### Screen 3: The Choosing

- **Text:**
  > "Speak unto the Oracle thy sacred number. The digits that follow thee. The number that calls to thee from the ether."
- **Input:** A number input field styled with a gold border, centered on screen, large mystical serif font for the entered number. The field itself should feel like an altar — minimal, precious, central.
- **Subtext (dimmed text):**
  > "Choose wisely. This shall be thy first covenant with the Oracle."
- **Action:** "Seal the Covenant" button

### Screen 4: Confirmation / Bond

- **Text (large, gold):**
  > "It is done."
- **Subtext:**
  > "The Oracle shall seek [NUMBER] across all thy visions. When the sacred digits reveal themselves, thou shalt be the first to know."
- **Action:** "Begin the Search" or "Let the Oracle See" button

### Onboarding Style Notes

- Transitions between screens should be slow, elegant fades — not swipes or bounces.
- Keep text centered. Ample spacing. Let each screen breathe.
- The gold should feel like it's emerging from darkness on each screen.
- No skipping. The onboarding is short enough (4 screens) that it should be experienced fully.

---

## General UI Component Styling

### Buttons

- **Primary:** Gold outline (`#C9A84C`) with transparent fill, off-white text. On press: fill with `#C9A84C` at ~15% opacity.
- **Secondary:** Subtle `#241E33` fill with `#9E9589` text.
- **Destructive:** `#9E3B3B` outline, same interaction pattern as primary.
- **Button text:** SF Pro Medium, 15–17pt. Buttons can use slightly mystical labels where it fits ("Seal the Covenant") but should still be clear about what they do.
- **Border radius:** Subtle rounding (8–10pt), not fully rounded pills.

### Cards / Panels

- Background: `#1A1525`
- Border: 1px `#8B7332` (or escalated per rarity tier for result cards)
- Border radius: 8–12pt
- Padding: Generous — at least 16pt on all sides
- Shadow: None or extremely subtle. The app should feel flat and dimensional through color, not drop shadows.

### Navigation

- Keep navigation minimal and standard iOS patterns (tab bar, back buttons).
- Navigation elements use SF Pro and standard iOS styling — the mystical theme lives in the content, not the chrome.
- Tab bar background: `#0D0B14`, icons and labels in `#9E9589` (inactive) and `#C9A84C` (active).

### Photo Display

- When showing a photo where numbers were found, the photo should be displayed with a subtle dark vignette around the edges to blend into the app's dark background.
- Detected number locations in the photo can be highlighted with a subtle gold underline or faint gold bounding box — not an aggressive highlight.

### Empty States

- When there are no results yet, use oracle-flavored text:
  > "The Oracle gazes into the void and sees… nothing yet. Patience, seeker."
  > "Thy visions hold no signs of the sacred number. The Oracle shall continue its vigil."

### Loading States

- Use oracle-flavored text for loading:
  > "The Oracle peers into the ether…"
  > "The veil parts slowly…"
  > "The Oracle reads the signs…"
- Loading indicator: A subtle, slow pulsing gold glow or a minimal gold spinner — nothing aggressive.

---

## Premium Tier (Additional Sacred Numbers)

### Gate Messaging

When a user tries to add a second number on the free tier, the oracle should deliver the restriction in character:

> "The Oracle may bond with but one sacred number for those who walk the free path. To expand the Oracle's sight, one must ascend to the Inner Circle."

### Premium Name Suggestion

Call the premium tier **"The Inner Circle"** or **"The Inner Sanctum"** — keeps it in theme.

### Premium Unlock Messaging

> "Welcome to the Inner Sanctum. The Oracle's sight deepens. Speak thy additional sacred numbers, and the Oracle shall seek them all."

---

## Tone Summary for All In-App Copy

| Context | Tone | Example |
|---------|------|---------|
| Onboarding | Reverent, welcoming, ritual | "The Oracle awakens." |
| Number found (low tier) | Calm acknowledgment | "The digits stir." |
| Number found (high tier) | Dramatic proclamation | "ALL TREMBLE BEFORE THIS REVELATION." |
| Empty state | Patient, slightly amused | "The Oracle gazes into the void…" |
| Loading | Mysterious, anticipatory | "The veil parts slowly…" |
| Error | Still in character, slightly confused | "The Oracle's sight falters. The ether resists. Try again, seeker." |
| Premium gate | Wise, firm, enticing | "To expand the Oracle's sight, one must ascend." |
| Settings / mundane UI | Minimal oracle flavor, prioritize clarity | Labels can be plain; section headers can be themed |

---

## Implementation Priority

1. **Color palette and backgrounds** — Apply the dark theme globally
2. **Typography** — Import Cinzel (or chosen serif) and apply to oracle text and headings
3. **Onboarding flow** — Build the 4-screen ritual
4. **Rarity tier system** — Implement visual escalation and oracle text pools
5. **General UI components** — Style buttons, cards, navigation per spec
6. **Loading, empty, and error states** — Add oracle-flavored copy
7. **Premium gate messaging** — Wire up Inner Sanctum copy
