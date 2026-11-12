# Mobile feel

Most reports that a web app "feels janky on mobile" are a tap delay, a gray flash on tap or a hover state that will not let go. Nearly every fix is one CSS declaration or one meta tag. Use media queries and never detect devices: touch and mouse coexist on tablets with trackpads and laptops with touch screens.

| Symptom | Fix |
|---|---|
| Hover state stuck after a tap | Wrap hover styles in `@media (hover: hover) and (pointer: fine)`. In Tailwind v4 the `hover:` variant already does this; in v3 set `future.hoverOnlyWhenSupported` |
| Gray or blue flash on tap | `-webkit-tap-highlight-color: transparent` on `html`, then give every tappable element its own `:active` state |
| Layout has the wrong height | `100dvh` for an app shell or bottom-pinned UI, `100svh` for a hero. `100vh` is the height with the browser bars collapsed, so it overflows on load |
| Page zooms into an input | Input font size of at least 16px. Never disable zoom with `user-scalable=no` or `maximum-scale=1` |
| Taps feel laggy | `touch-action: manipulation` on buttons and links, and press feedback on `:active` or `pointerdown`, not on click |
| Pull-to-refresh hijacks scrolling | `overscroll-behavior: none` on `html, body`, and `overscroll-behavior: contain` on inner scroll areas |
| Content stops at the notch | `viewport-fit=cover` in the viewport meta tag, then pad fixed headers, bottom bars and sheets with `env(safe-area-inset-*)`. Without the meta tag those values are 0 |
| Long press selects button text | `user-select: none`, `-webkit-user-select: none` and `-webkit-touch-callout: none` on controls only. Body text stays selectable |
| Carousel scrolls the page vertically | `touch-action: pan-y` on a horizontal gesture surface. For a native scroll track, use `scroll-snap-type: x mandatory` |
| Status bar color does not match | One `theme-color` meta tag per color scheme, matching the color at the top of the page |

Set the right keyboard on inputs while you are there: `inputmode="numeric"` for codes, `inputmode="decimal"` for amounts, `type="email"` and `type="tel"`, `autocapitalize="none"` on usernames and codes, and `enterkeyhint` so that the return key says what it does.

Details that the table leaves out:

- Apply each fix where its reason applies. `user-select: none` is correct on a button and a defect on body text.
- When the design calls for smaller input text on desktop, set 16px only under `@media (pointer: coarse)`.
- `dvh` resizes as the browser bars collapse, which suits an app shell and shifts the layout of marketing content mid-scroll. `svh` is stable. `lvh` is the old `vh` and is rarely what you want.
- Inside `calc()`, give `env()` a fallback: `env(safe-area-inset-bottom, 0px)`.
- A `touch-action` value names what the browser may still do. `pan-y` leaves vertical panning to the browser, `pan-x` leaves horizontal panning, and `none` gives every axis to the element.
- When the app switches theme with a class and not the system setting, update the `theme-color` tag from JavaScript. An installed PWA takes the same decision from `apple-mobile-web-app-status-bar-style` and the manifest's `theme_color` and `background_color`.

## Baseline

Ship this before the first component of an app that will be used on phones:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content" />
<meta name="theme-color" media="(prefers-color-scheme: light)" content="#ffffff" />
<meta name="theme-color" media="(prefers-color-scheme: dark)" content="#0a0a0a" />
```

```css
html {
  -webkit-tap-highlight-color: transparent;
  -webkit-text-size-adjust: 100%;
  overscroll-behavior: none;
}
input, textarea, select { font-size: 16px; }
button, a, [role="button"] {
  touch-action: manipulation;
  user-select: none;
  -webkit-user-select: none;
}
```

Leave `overscroll-behavior: none` off `html` when the app is a scrolling document where pull-to-refresh is welcome. Never stop overscroll with a `touchmove` listener that calls `preventDefault()`, and never put `touch-action: none` on something the user needs to scroll past.

## Checking on a phone

None of these problems reproduce in desktop device emulation. Connect a phone over USB, run the dev server on `0.0.0.0`, open it by the machine's LAN address, and inspect with Safari's Develop menu (iOS) or `chrome://inspect` (Android). Use a phone that is a few years old. Test with the keyboard open and once in landscape, and as an installed PWA when that is a target, because standalone mode changes the viewport, the safe areas and the status bar.

After fixing, report the symptom matched and its cause in one line, the file and declaration changed, and which fixes the user needs to confirm on a real phone.
