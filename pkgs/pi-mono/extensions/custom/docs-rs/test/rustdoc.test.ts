import { describe, expect, it } from "vitest";
import { renderItemBody, listMembers } from "../src/rustdoc.ts";
import { mockDoc, chunkByHit, itertoolsHit } from "./fixtures.ts";

describe("renderItemBody — function signatures", () => {
  it("includes generic type parameters <K, F>", () => {
    const body = renderItemBody(mockDoc, chunkByHit);
    expect(body.signature).toContain("<K, F>");
  });

  it("includes where clause keyword", () => {
    const body = renderItemBody(mockDoc, chunkByHit);
    expect(body.signature).toContain("where");
  });

  it("renders Self: Sized bound", () => {
    const body = renderItemBody(mockDoc, chunkByHit);
    expect(body.signature).toContain("Self: Sized");
  });

  it("renders F: FnMut bound with parenthesized args", () => {
    const body = renderItemBody(mockDoc, chunkByHit);
    expect(body.signature).toContain("FnMut(");
    expect(body.signature).toContain("-> K");
  });

  it("renders K: PartialEq bound", () => {
    const body = renderItemBody(mockDoc, chunkByHit);
    expect(body.signature).toContain("K: PartialEq");
  });

  it("still renders inputs and output", () => {
    const body = renderItemBody(mockDoc, chunkByHit);
    expect(body.signature).toContain("fn");
    expect(body.signature).toContain("chunk_by");
    expect(body.signature).toContain("ChunkBy");
  });
});

describe("listMembers", () => {
  it("returns all trait methods", () => {
    const members = listMembers(mockDoc, itertoolsHit);
    expect(members).toHaveLength(2);
  });

  it("includes full signature for each method", () => {
    const members = listMembers(mockDoc, itertoolsHit);
    const chunkBy = members.find((m) => m.name === "chunk_by");
    expect(chunkBy).toBeDefined();
    expect(chunkBy?.signature).toContain("<K, F>");
    expect(chunkBy?.signature).toContain("where");
  });

  it("includes deprecation info for deprecated methods", () => {
    const members = listMembers(mockDoc, itertoolsHit);
    const groupBy = members.find((m) => m.name === "group_by");
    expect(groupBy?.deprecated).toBe("Use .chunk_by() instead");
    expect(groupBy?.deprecatedSince).toBe("0.13.0");
  });

  it("null deprecation for non-deprecated methods", () => {
    const members = listMembers(mockDoc, itertoolsHit);
    const chunkBy = members.find((m) => m.name === "chunk_by");
    expect(chunkBy?.deprecated).toBeNull();
    expect(chunkBy?.deprecatedSince).toBeNull();
  });
});
