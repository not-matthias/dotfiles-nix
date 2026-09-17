---
description: Do not branch on a string-literal union/enum member with a ternary in TypeScript; use an IIFE with switch/case
condition:
  - '[!=]==\s*[\x27"][\w-]+[\x27"]\s*\?(?![?.])'
  - '[\x27"][\w-]+[\x27"]\s*[!=]==\s*\w+(\.\w+)*\s*\?(?![?.])'
scope:
  - 'tool:edit(*.ts)'
  - 'tool:edit(*.tsx)'
  - 'tool:write(*.ts)'
  - 'tool:write(*.tsx)'
interruptMode: always
---

Do not select behavior per member of a string-literal union (enum-like type) with a
ternary. A ternary silently falls through to the `else` branch when a new member is
added. Use an IIFE with a `switch` on the discriminant and one `case` per member, so
TypeScript's exhaustiveness checking forces every new member to be handled:

```ts
const areaOf: (shape: Shape) => number = (() => {
  switch (kind) {
    case "circle":
      return (shape) => Math.PI * (shape as Circle).radius ** 2;
    case "square":
      return (shape) => (shape as Square).side ** 2;
  }
})();
```

Plain boolean ternaries that do not compare against a union member are fine.
