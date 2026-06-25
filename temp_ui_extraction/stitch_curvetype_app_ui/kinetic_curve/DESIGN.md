---
name: Kinetic Curve
colors:
  surface: '#1d100a'
  surface-dim: '#1d100a'
  surface-bright: '#46362e'
  surface-container-lowest: '#170b06'
  surface-container-low: '#261812'
  surface-container: '#2b1c16'
  surface-container-high: '#362720'
  surface-container-highest: '#41312a'
  on-surface: '#f8ddd2'
  on-surface-variant: '#e2bfb0'
  inverse-surface: '#f8ddd2'
  inverse-on-surface: '#3d2d26'
  outline: '#a98a7d'
  outline-variant: '#5a4136'
  surface-tint: '#ffb693'
  primary: '#ffb693'
  on-primary: '#561f00'
  primary-container: '#ff6b00'
  on-primary-container: '#572000'
  inverse-primary: '#a04100'
  secondary: '#ffb871'
  on-secondary: '#4a2800'
  secondary-container: '#a76100'
  on-secondary-container: '#fff7f2'
  tertiary: '#9ccaff'
  on-tertiary: '#003257'
  tertiary-container: '#059eff'
  on-tertiary-container: '#003357'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbcc'
  primary-fixed-dim: '#ffb693'
  on-primary-fixed: '#351000'
  on-primary-fixed-variant: '#7a3000'
  secondary-fixed: '#ffdcbe'
  secondary-fixed-dim: '#ffb871'
  on-secondary-fixed: '#2d1600'
  on-secondary-fixed-variant: '#6a3c00'
  tertiary-fixed: '#d0e4ff'
  tertiary-fixed-dim: '#9ccaff'
  on-tertiary-fixed: '#001d35'
  on-tertiary-fixed-variant: '#00497b'
  background: '#1d100a'
  on-background: '#f8ddd2'
  surface-variant: '#41312a'
typography:
  display-xl:
    fontFamily: Outfit
    fontSize: 64px
    fontWeight: '800'
    lineHeight: 72px
    letterSpacing: -0.02em
  display-xl-mobile:
    fontFamily: Outfit
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Outfit
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Outfit
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Outfit
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 20px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The design system is engineered for a high-performance creative environment, focusing on energy, precision, and a "dark mode first" studio aesthetic. It targets professional creators, graphic designers, and social media influencers who require a focused workspace that minimizes eye strain while emphasizing their creative output.

The visual style is **High-Contrast Bold**. It utilizes a deep jet-black foundation to allow the vivid orange accents to "pop" with intensity. This isn't just a workspace; it's a performance tool. The atmosphere should feel premium and authoritative, drawing inspiration from high-end video editing suites and modern hardware interfaces. Large typography and expansive hit areas ensure the interface feels tactile and immediate.

## Colors

This design system employs a strict monochromatic dark base with a high-energy orange primary palette. 

- **Primary (#FF6B00):** Used for primary actions, active tool states, and critical paths.
- **Secondary (#FFA94D):** Used for secondary interactions, hover states, and subtle highlights.
- **Background (#0D0D0D):** The absolute foundation of the UI, providing a "void" effect that eliminates distractions.
- **Surface (#1A1A1A):** Used for panels, cards, and modal containers to create a subtle hierarchy of depth.
- **Text:** High-contrast White (#FFFFFF) for maximum readability against the dark backgrounds.

Avoid any use of cool tones (purples, blues, or indigos). All status colors (success, warning) should be weighted toward warmer or neutral spectrums to maintain the brand's fiery heat.

## Typography

The typography uses **Outfit** exclusively to maintain a geometric, modern, and tech-forward appearance.

- **Display & Headlines:** Use heavy weights (700-800) with tight letter spacing to create an impactful, editorial feel.
- **Body:** Standardized at 16px and 18px for clarity. 
- **Labels:** Use uppercase for functional labels (e.g., sidebar headers, small button text) to differentiate from content.
- **Responsive:** Headlines scale down significantly on mobile to maintain structural integrity and avoid excessive line-wrapping in tight canvases.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid** model with generous safe areas to accommodate large-scale text manipulation tools.

- **Grid:** A 12-column grid for desktop, 8-column for tablet, and 4-column for mobile.
- **Margins:** Large 32px margins on desktop allow the toolsets to feel "unboxed" and airy.
- **Rhythm:** Spacing follows a 4px base unit. Component padding should lean towards the `md` (16px) or `lg` (24px) units to ensure the UI feels "professional" and not cramped.
- **Canvas Focus:** The central workspace should remain as expansive as possible, with sidebars using fixed widths (280px-320px) and the canvas area fluidly adapting.

## Elevation & Depth

In a strict dark mode, depth is created through **Tonal Layers** and **Orange Glow Effects**.

- **Layers:** Surface containers (#1A1A1A) sit on top of the background (#0D0D0D). For elements requiring higher focus (like active popovers or floating toolbars), a third tier of #262626 is used.
- **Shadows:** Avoid traditional black shadows. Instead, use "Glow Shadows" for active primary elements—a soft, low-opacity orange blur (`0px 4px 20px rgba(255, 107, 0, 0.2)`) to make buttons and active indicators appear to emit light.
- **Borders:** Use subtle 1px borders (#333333) to define card boundaries rather than heavy shadows to maintain a sleek, flat studio look.

## Shapes

The shape language is defined by **Smooth, Modern Curves**. All primary UI containers, buttons, and input fields utilize a 20px corner radius. This substantial rounding softens the high-contrast color palette, making the interface feel sophisticated rather than aggressive.

- **Primary Radius:** 20px for cards, buttons, and main tool panels.
- **Nested Elements:** Elements inside a 20px container should use a slightly reduced radius (12px or 16px) to maintain visual concentricity.
- **Circle Icons:** Small action icons (like close buttons or mini-toggles) may use a full circle/pill shape.

## Components

- **Buttons:** Primary buttons use #FF6B00 with white text. Use a 20px radius and a subtle orange glow on hover. Secondary buttons are outlined with #333333 or are ghost buttons with #FFFFFF text.
- **Input Fields:** Background should be #1A1A1A with a 20px radius. On focus, the border transitions to #FF6B00 with a faint glow.
- **Cards:** Use #1A1A1A with no shadow, but a subtle 1px border. Padding should be a minimum of 24px (lg).
- **Tool Sliders:** The track should be #333333, and the active fill and handle should be #FF6B00. The handle should be a large, tactile circle.
- **Chips/Badges:** Small, 20px rounded containers with uppercase `label-sm` text. Use low-opacity orange backgrounds (`rgba(255, 107, 0, 0.1)`) with vivid orange text for active states.
- **Lists:** Items should have a hover state of #262626 with a 12px internal radius for the selection highlight.
- **Curved Text Controls:** Bespoke circular handles and "arc" indicators should use #FF6B00 to clearly signify they are the primary interaction points for the app's core feature.