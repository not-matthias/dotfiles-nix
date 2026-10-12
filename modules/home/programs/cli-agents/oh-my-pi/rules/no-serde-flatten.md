---
description: Do not introduce #[serde(flatten)] in Rust; it buffers every field through serde's private Content type
condition: '#\[serde\([^\]]*\bflatten\b'
scope:
  - 'tool:edit(*.rs)'
  - 'tool:write(*.rs)'
interruptMode: always
---

Do not add `#[serde(flatten)]`. Deserializing a flattened struct or enum cannot
stream: serde first collects every remaining key and value into its internal
`Content` buffer and only then hands that buffer to the inner type. As a result:

- Every field allocates, including fields the caller skips or ignores. A hot
  decode loop measured 3–35 allocations per event, where a plain struct needed 0.
- Borrowed `&str` and `&[u8]` fields cannot borrow from the input. Compact
  formats such as msgpack and bincode also lose type information when they go
  through `Content`.
- `deny_unknown_fields` stops working, and the error messages lose field context.

Combining it with an internally tagged enum (`#[serde(tag = "...")]`) makes this
worse, because the tag lookup buffers the whole map as well.

Alternatives:

- Keep the inner value as a nested field (`kind: Kind`) and let the wire format
  nest it.
- Use an externally or adjacently tagged enum (`#[serde(tag = "t", content = "c")]`)
  so the variant is known before its fields are read.
- If the flat wire format is fixed, hand-write `Deserialize` with a map visitor
  that reads the fields directly, and keep `Serialize` byte-identical.
- To read only a few fields from a hot stream, deserialize into a small struct
  that lists just those fields. Unknown fields are skipped with `IgnoredAny`,
  which does not allocate.

If flatten is truly needed (cold config parsing, existing wire compatibility),
say why in a comment next to the attribute.
