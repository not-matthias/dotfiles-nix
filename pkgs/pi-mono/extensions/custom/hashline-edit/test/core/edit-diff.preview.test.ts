import { describe, expect, it } from "vitest";
import { buildCompactHashlineDiffPreview, generateDiffString } from "../../src/edit-diff";

describe("generateDiffString", () => {
  it("adds hash hints for context and addition lines but not deletions", () => {
    const diff = generateDiffString("alpha\nbeta\ngamma", "alpha\nBETA\ngamma").diff;

    expect(diff).toContain(" 1#");
    expect(diff).toContain(":alpha");
    expect(diff).toContain("+2#");
    expect(diff).toContain(":BETA");
    expect(diff).toContain("-2    beta");
    expect(diff).toContain(" 3#");
    expect(diff).toContain(":gamma");
  });
});

describe("buildCompactHashlineDiffPreview", () => {
  it("collapses long unchanged runs and counts add/remove lines", () => {
    const diff = [
      " 1 ctx-a",
      " 2 ctx-b",
      " 3 ctx-c",
      " 4 ctx-d",
      "+5 added",
      "-6 removed",
      " 7 tail-a",
      " 8 tail-b",
      " 9 tail-c",
    ].join("\n");

    const preview = buildCompactHashlineDiffPreview(diff);

    expect(preview.preview).toContain("... 2 more unchanged lines");
    expect(preview.addedLines).toBe(1);
    expect(preview.removedLines).toBe(1);
  });
});
