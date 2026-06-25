---
name: CurveType Creative Studio
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#464555'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#777587'
  outline-variant: '#c7c4d8'
  surface-tint: '#4d44e3'
  primary: '#3525cd'
  on-primary: '#ffffff'
  primary-container: '#4f46e5'
  on-primary-container: '#dad7ff'
  inverse-primary: '#c3c0ff'
  secondary: '#4648d4'
  on-secondary: '#ffffff'
  secondary-container: '#6063ee'
  on-secondary-container: '#fffbff'
  tertiary: '#41485e'
  on-tertiary: '#ffffff'
  tertiary-container: '#586076'
  on-tertiary-container: '#d4dbf5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#0f0069'
  on-primary-fixed-variant: '#3323cc'
  secondary-fixed: '#e1e0ff'
  secondary-fixed-dim: '#c0c1ff'
  on-secondary-fixed: '#07006c'
  on-secondary-fixed-variant: '#2f2ebe'
  tertiary-fixed: '#dae2fd'
  tertiary-fixed-dim: '#bec6e0'
  on-tertiary-fixed: '#131b2e'
  on-tertiary-fixed-variant: '#3f465c'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Outfit
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Outfit
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-md:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  caption:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 20px
  margin-tablet: 40px
---

## Brand & Style

The design system is engineered for a high-performance creative environment where clarity and focus are paramount. It adopts a **Modern Corporate Minimalism** style, blending the structural integrity of a productivity tool with the fluid elegance of a creative suite. 

The aesthetic is characterized by expansive whitespace, a restrained professional color palette, and high-contrast typography. It draws inspiration from the disciplined utility of Linear and the approachable modularity of Notion. The interface feels lightweight and responsive, prioritizing content creation over decorative UI elements. High-quality iconography and subtle micro-interactions provide the "polished" feel necessary for a premium SaaS experience.

## Colors

This design system utilizes a sophisticated **Indigo-Slate** palette. The primary Indigo (#4F46E5) serves as the main action color, providing a sense of intelligence and reliability.

- **Action Palette:** Primary Indigo and its lighter Accent variation are used for interactive elements, progress indicators, and primary brand moments.
- **Surface Palette:** The background uses a Cool Slate tint (#F8FAFC) to reduce eye strain, while pure White (#FFFFFF) is reserved for cards and elevated surfaces to create clear visual separation.
- **Typography & Borders:** Text colors are strictly tiered from Deep Slate (#0F172A) for maximum legibility to Muted Blue-Grey (#64748B) for metadata. Borders use a subtle Slate (#E2E8F0) to define structure without adding visual noise.

## Typography

The system employs a dual-font strategy. **Outfit** is used for headlines and titles to provide a modern, geometric character that feels creative and "designed." **Inter** is used for all body text, inputs, and labels to ensure maximum legibility and a professional, systematic feel.

- **Headlines:** Use tight letter-spacing and high weights to create strong visual anchors.
- **Body:** Standardized on Inter with a 1.5x line-height ratio for optimal reading comfort in long-form settings or complex data views.
- **Labels:** Utilize medium-to-semibold weights and slight tracking increases to differentiate them from body text at smaller scales.

## Layout & Spacing

The design system follows a **strict 4px/8px grid system**. The layout is fluid but constrained by safe margins to ensure content remains centered and readable on mobile devices.

- **Mobile Layout:** 4-column fluid grid with 16px gutters and 20px outside margins.
- **Rhythm:** Vertical spacing between related components should use `md` (16px), while spacing between distinct sections should use `xl` (32px).
- **Safe Areas:** Mobile views must respect the notch and home indicator safe areas, with bottom sheets using a minimum 24px top margin from the status bar.

## Elevation & Depth

Depth is communicated through **Tonal Layering** and soft, natural shadows. The system avoids heavy borders in favor of subtle elevation changes.

- **Level 0 (Background):** #F8FAFC - The base canvas.
- **Level 1 (Cards/Surfaces):** #FFFFFF - Uses a very soft, diffused shadow (0px 2px 4px rgba(15, 23, 42, 0.05)) to sit slightly above the background.
- **Level 2 (Modals/Popovers):** #FFFFFF - Uses a more pronounced shadow (0px 8px 24px rgba(15, 23, 42, 0.08)) to indicate floating priority.
- **Interactive States:** On hover or press, elements may transition their shadow or border-color, but should never use inner glows or neomorphic extrusions.

## Shapes

The shape language is "Rounded-Soft." It avoids sharp corners to maintain a friendly, modern SaaS aesthetic, but keeps the radii disciplined to remain professional.

- **Large Containers:** Cards and primary containers use 16px.
- **Interactive Elements:** Buttons use 14px and inputs use 12px to create a subtle nested appearance when placed inside cards.
- **Sheet Components:** Bottom sheets use a 24px radius only on the top corners to emphasize their role as an emerging layer from the bottom of the screen.

## Components

### Buttons
- **Primary:** Background #4F46E5, Text #FFFFFF. 14px radius. 
- **Secondary:** Background #F1F5F9 (Light Slate), Text #0F172A.
- **Size:** Large buttons should be 56px height for mobile accessibility; small buttons 36px.

### Input Fields
- **Default:** 12px radius, 1px border (#E2E8F0), Background #FFFFFF.
- **Focused:** 2px border (#4F46E5), Label floats or transforms using Outfit Semibold.
- **Error:** 1px border (#EF4444), Text #EF4444.

### Cards
- **Default:** 16px radius, White surface, 1px subtle border (#F1F5F9), Soft elevation level 1.
- **Padding:** 20px padding internally for standard cards.

### Chips & Badges
- **Style:** 100px (Pill) radius. 
- **Active:** Background #EEF2FF (Light Indigo tint), Text #4F46E5.
- **Inactive:** Background #F1F5F9, Text #64748B.

### Lists
- **Separators:** 1px line (#E2E8F0).
- **Vertical Padding:** 16px for standard items.
- **Interaction:** Subtle background change to #F8FAFC on press.

### Bottom Sheets
- **Radius:** 24px top-only.
- **Handle:** 32x4px pill, #E2E8F0 color, centered 8px from top.