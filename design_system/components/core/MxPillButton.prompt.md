One of N views of the same content — the deck list's filter and sort switches.

```jsx
<MxPillButton label="Due only" icon="filter_list" isSelected={dueOnly} onClick={toggle} />
<MxPillButton label="A–Z" icon="swap_vert" isSelected={byName} semanticLabel="Sort by name" onClick={sort} />
```

Selected borrows the navigation bar's indicator pair (`secondary-container`), so
"this one is active" looks the same whether it is a tab or a filter. The tap
target is padded to 48px even though the pill itself is shorter.
