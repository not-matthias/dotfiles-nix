import { describe, expect, it } from "vitest";
import { formatItem } from "../src/format.ts";
import type { ItemHit, ItemBody } from "../src/rustdoc.ts";

const hit: ItemHit = { id: "1", path: "itertools::group_by", kind: "function" };
const body: ItemBody = { signature: "fn group_by(self) -> ()", members: [] };

describe("formatItem — deprecation", () => {
  it("includes deprecation since version", () => {
    const text = formatItem(
      "itertools", "0.15.0", hit, body, "docs",
      "Use .chunk_by() instead", "0.13.0",
    );
    expect(text).toContain("0.13.0");
    expect(text).toContain("deprecated");
  });

  it("works without since version", () => {
    const text = formatItem(
      "itertools", "0.15.0", hit, body, "docs",
      "deprecated", null,
    );
    expect(text).toContain("deprecated");
  });

  it("omits deprecation line when not deprecated", () => {
    const text = formatItem(
      "itertools", "0.15.0", hit, body, "docs",
      null, null,
    );
    expect(text).not.toContain("deprecated");
  });
});
