How far through something the user is — a deck's mastery, a session's run.

```jsx
<MxProgressBar value={0.62} label="Learned" valueLabel="62%" size="sm" />
<MxProgressBar value={3 / 20} valueLabel="3 of 20" />
```

Draws in `--color-progress-*`, never the accent: a bar in the accent colour sits
beside a button in the accent colour and neither reads as the pressable one. At
100% the fill turns `--color-progress-complete` and the value label follows it.
