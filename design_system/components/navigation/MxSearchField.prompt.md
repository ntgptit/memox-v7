The search bar under an app bar — filled, pill, no label.

```jsx
<MxSearchField value={q} onChange={setQ} placeholder="Search in Academic Word List" resultCount={matches.length} />
```

Name the **scope** in the placeholder, not the action: on a nested level the user
needs to know whether they are searching this deck or the whole library. The
clear button and the count appear only once something has been typed. Use
`MxTextField` for form input; this is for filtering a list.
