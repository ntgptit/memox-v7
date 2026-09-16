---
name: memox-design
description: Use this skill to generate well-branded interfaces and assets for MemoX (a local-first flashcard / spaced-repetition study app), either for production or throwaway prototypes/mocks. Contains essential design guidelines, color & type tokens, the Plus Jakarta Sans font, the frozen Mx* component family, and a full app UI kit for prototyping.
user-invocable: true
---

Read the `readme.md` file within this skill first, and explore the other available files.

MemoX is a three-layer system with **frozen identifiers**:
- **Tokens** — all visual values are `--memox-<role>` CSS custom properties (`tokens/*.css`, light in `:root`, dark in `[data-theme="dark"]`). Switch theme by setting `data-theme`; never override inside components. Token names are additive-only.
- **Components** — the `Mx*` family (`components/<group>/`), each with a stable PascalCase name and a stable base class (`MxCard`↔`card`, `MxButton`↔`btn`, etc.). Variants are modifiers, never new names. See each component's `.prompt.md`.
- **Screens** — assembled only from components; every meaningful node carries a stable `data-mx-node="<screen>/<node>"` semantic id.

The golden rule: changing a **value** is free; changing a **name or id** breaks the system. Keep `data-mx-node` ids stable across redesigns.

Icons: Material Symbols Rounded (Google Fonts CDN). No emoji in UI.

If creating visual artifacts (slides, mocks, throwaway prototypes), copy assets out and create static HTML files for the user to view — link `styles.css`, the Material Symbols CDN, and either use the component classes directly or the bundled `Mx*` components. If working on production code, copy the tokens/components and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without other guidance, ask them what they want to build, ask a few questions, and act as an expert MemoX designer who outputs HTML artifacts **or** production code, depending on the need.
