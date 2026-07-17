/**
 * docs.rs / crates.io extension for oh-my-pi.
 *
 * Native and dependency-free: uses only the injected `pi` API (`pi.zod`,
 * `pi.registerTool`) plus Node built-ins (global fetch, node:zlib). The single
 * harness import is type-only and erased by esbuild, so the compiled index.js
 * has zero runtime dependency on the harness package.
 */

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

import { crateMeta, searchCrates } from "./src/crates-io.ts";
import {
  fetchRustdoc,
  findItem,
  listMembers,
  renderItemBody,
  rootDocs,
  topLevelItems,
} from "./src/rustdoc.ts";
import {
  formatItem,
  formatItemNotFound,
  formatMembers,
  formatOverview,
  formatSearch,
} from "./src/format.ts";

function errorResult(message: string) {
  return {
    content: [{ type: "text" as const, text: `docs.rs error: ${message}` }],
    details: { error: message },
  };
}

export default function (pi: ExtensionAPI) {
  const { z } = pi.zod;

  pi.registerTool({
    name: "docs_rs_search",
    label: "Search crates.io",
    description:
      "Search crates.io for Rust crates by keyword. Returns name, version, description and download count for the top matches.",
    parameters: z.object({
      query: z.string().describe("crate search keywords"),
      limit: z.number().int().min(1).max(30).default(10).optional(),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      try {
        const result = await searchCrates(params.query, params.limit ?? 10);
        return {
          content: [{ type: "text" as const, text: formatSearch(params.query, result) }],
          details: result,
        };
      } catch (e) {
        return errorResult(e instanceof Error ? e.message : String(e));
      }
    },
  });

  pi.registerTool({
    name: "docs_rs_crate_overview",
    label: "Crate overview",
    description:
      "Get an overview of a Rust crate: crates.io metadata plus, when available, the top-level rustdoc modules/structs/traits/functions and crate-level docs.",
    parameters: z.object({
      crate: z.string(),
      version: z.string().default("latest").optional(),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      try {
        const version = params.version ?? "latest";
        const meta = await crateMeta(params.crate);
        const doc = await fetchRustdoc(params.crate, version);
        const rustdoc = doc
          ? { rootDocs: rootDocs(doc), topLevel: topLevelItems(doc) }
          : null;
        return {
          content: [{ type: "text" as const, text: formatOverview(meta, rustdoc, version) }],
          details: { meta, hasRustdoc: !!doc, topLevel: rustdoc?.topLevel ?? null },
        };
      } catch (e) {
        return errorResult(e instanceof Error ? e.message : String(e));
      }
    },
  });

  pi.registerTool({
    name: "docs_rs_item",
    label: "Item docs",
    description:
      "Look up documentation for a specific item in a Rust crate (struct, enum, trait, function, …) by path, e.g. sync::Mutex or tokio::sync::Mutex. Returns signature, docs and members.",
    parameters: z.object({
      crate: z.string(),
      path: z.string().describe("item path, e.g. sync::Mutex or tokio::sync::Mutex"),
      version: z.string().default("latest").optional(),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      try {
        const version = params.version ?? "latest";
        const doc = await fetchRustdoc(params.crate, version);
        if (doc === null) {
          const text = `Structured rustdoc JSON not available for ${params.crate}@${version}. Try version:"latest" or browse https://docs.rs/${params.crate}/${version}/`;
          return {
            content: [{ type: "text" as const, text }],
            details: { hasRustdoc: false },
          };
        }
        const { hit, suggestions } = findItem(doc, params.path);
        if (!hit) {
          return {
            content: [
              {
                type: "text" as const,
                text: formatItemNotFound(params.crate, params.path, suggestions),
              },
            ],
            details: { found: false, suggestions },
          };
        }
        const item = doc.index[hit.id];
        const body = renderItemBody(doc, hit);
        const deprecation = item?.deprecation;
        const deprecated = deprecation?.note ?? (deprecation ? "deprecated" : null);
        const deprecatedSince = deprecation?.since ?? null;
        const text = formatItem(
          params.crate, version, hit, body, item?.docs ?? "",
          deprecated, deprecatedSince,
        );
        return {
          content: [{ type: "text" as const, text }],
          details: {
            path: hit.path,
            kind: hit.kind,
            signature: body.signature,
            members: body.members,
          },
        };
      } catch (e) {
        return errorResult(e instanceof Error ? e.message : String(e));
      }
    },
  });

  pi.registerTool({
    name: "docs_rs_members",
    label: "List members",
    description:
      "List all methods, fields, and variants of a trait, struct, or enum in a Rust crate, with full signatures. Useful for discovering what methods a trait provides.",
    parameters: z.object({
      crate: z.string(),
      path: z.string().describe("item path, e.g. Itertools or tokio::stream::StreamExt"),
      version: z.string().default("latest").optional(),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      try {
        const version = params.version ?? "latest";
        const doc = await fetchRustdoc(params.crate, version);
        if (doc === null) {
          const text = `Structured rustdoc JSON not available for ${params.crate}@${version}.`;
          return {
            content: [{ type: "text" as const, text }],
            details: { hasRustdoc: false },
          };
        }
        const { hit, suggestions } = findItem(doc, params.path);
        if (!hit) {
          return {
            content: [
              {
                type: "text" as const,
                text: formatItemNotFound(params.crate, params.path, suggestions),
              },
            ],
            details: { found: false, suggestions },
          };
        }
        const members = listMembers(doc, hit);
        const text = formatMembers(params.crate, version, hit, members);
        return {
          content: [{ type: "text" as const, text }],
          details: { path: hit.path, kind: hit.kind, members },
        };
      } catch (e) {
        return errorResult(e instanceof Error ? e.message : String(e));
      }
    },
  });
}
