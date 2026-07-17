import type { RustdocDoc, ItemHit } from "../src/rustdoc.ts";

// Mock rustdoc JSON matching the real itertools chunk_by/group_by shape.
// Verified against https://docs.rs/crate/itertools/latest/json.gz (id 1345).

const fnGenerics = {
  params: [
    { name: "K", kind: { type: { bounds: [], default: null, is_synthetic: false } } },
    { name: "F", kind: { type: { bounds: [], default: null, is_synthetic: false } } },
  ],
  where_predicates: [
    {
      bound_predicate: {
        type: { generic: "Self" },
        bounds: [{
          trait_bound: {
            trait: { path: "Sized", id: 197, args: null },
            generic_params: [],
            modifier: "none",
          },
        }],
        generic_params: [],
      },
    },
    {
      bound_predicate: {
        type: { generic: "F" },
        bounds: [{
          trait_bound: {
            trait: {
              path: "FnMut",
              id: 337,
              args: {
                parenthesized: {
                  inputs: [{
                    borrowed_ref: {
                      lifetime: null,
                      is_mutable: false,
                      type: {
                        qualified_path: {
                          name: "Item",
                          args: null,
                          self_type: { generic: "Self" },
                          trait: { path: "", id: 157, args: null },
                        },
                      },
                    },
                  }],
                  output: { generic: "K" },
                },
              },
            },
            generic_params: [],
            modifier: "none",
          },
        }],
        generic_params: [],
      },
    },
    {
      bound_predicate: {
        type: { generic: "K" },
        bounds: [{
          trait_bound: {
            trait: { path: "PartialEq", id: 985, args: null },
            generic_params: [],
            modifier: "none",
          },
        }],
        generic_params: [],
      },
    },
  ],
};

const fnSig = {
  inputs: [
    ["self", { generic: "Self" }],
    ["key", { generic: "F" }],
  ],
  output: {
    resolved_path: {
      path: "ChunkBy",
      id: 72,
      args: {
        angle_bracketed: {
          args: [
            { type: { generic: "K" } },
            { type: { generic: "Self" } },
            { type: { generic: "F" } },
          ],
          constraints: [],
        },
      },
    },
  },
  is_c_variadic: false,
};

export const mockDoc = {
  root: "0",
  index: {
    "1": {
      id: 1,
      name: "chunk_by",
      inner: {
        function: {
          sig: fnSig,
          generics: fnGenerics,
          header: { is_const: false, is_unsafe: false, is_async: false, abi: "Rust" },
          has_body: true,
        },
      },
      deprecation: null,
    },
    "2": {
      id: 2,
      name: "group_by",
      inner: {
        function: {
          sig: fnSig,
          generics: fnGenerics,
          header: { is_const: false, is_unsafe: false, is_async: false, abi: "Rust" },
          has_body: true,
        },
      },
      deprecation: { since: "0.13.0", note: "Use .chunk_by() instead" },
    },
    "3": {
      id: 3,
      name: "Itertools",
      inner: { trait: { items: [1, 2] } },
    },
  },
  paths: {
    "3": { path: ["itertools", "Itertools"], kind: "trait", crate_id: 0 },
  },
  format_version: 36,
} as unknown as RustdocDoc;

export const chunkByHit: ItemHit = { id: "1", path: "itertools::chunk_by", kind: "function" };
export const groupByHit: ItemHit = { id: "2", path: "itertools::group_by", kind: "function" };
export const itertoolsHit: ItemHit = { id: "3", path: "itertools::Itertools", kind: "trait" };
