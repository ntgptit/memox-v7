MxCard — the rounded content surface everything sits on. Elevated by default; `variant` switches to flat, muted, solid primary, or soft-primary tint.

```jsx
<MxCard node="dashboard/due-summary" variant="primary" interactive>
  <div className="section-head__title">142 cards due</div>
</MxCard>
```

Variants: `flat` (hairline), `muted` (sunken), `primary` (brand solid), `primary-soft` (tint). `interactive` adds lift + press scale.