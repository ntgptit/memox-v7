MxSegmentedControl — a pill of 2–3 mutually-exclusive segments; the active one gets a raised surface.

```jsx
<MxSegmentedControl node="stats/range" value={range} onChange={setRange} block
  segments={[{value:'week',label:'Week'},{value:'month',label:'Month'},{value:'year',label:'Year'}]} />
```