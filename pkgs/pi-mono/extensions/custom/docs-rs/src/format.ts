/**
 * Pure output-text builders (no I/O). Consume the typed results produced by
 * crates-io.ts / rustdoc.ts.
 */

import type { CrateMeta, CrateSearchResult } from "./crates-io.ts";
import type { ItemBody, ItemHit, MemberInfo } from "./rustdoc.ts";

export function truncate(s: string, n: number): string {
  return s.length > n ? `${s.slice(0, n)}\n… (truncated)` : s;
}

export function formatSearch(query: string, result: CrateSearchResult): string {
  const lines = [`Found ${result.total} crates for "${query}" (showing ${result.crates.length}):`];
  result.crates.forEach((c, i) => {
    lines.push(
      `${i + 1}. ${c.name} v${c.version} — ${c.description} (⬇ ${c.downloads.toLocaleString()})`,
    );
  });
  return lines.join("\n");
}

const KIND_LABELS: Record<string, string> = {
  module: "Modules",
  struct: "Structs",
  enum: "Enums",
  trait: "Traits",
  function: "Functions",
  type_alias: "Type aliases",
  constant: "Constants",
  macro: "Macros",
  primitive: "Primitives",
};

export function formatOverview(
  meta: CrateMeta,
  rustdoc: { rootDocs: string; topLevel: Record<string, string[]> } | null,
  version: string,
): string {
  const lines = [`${meta.name} v${meta.stableVersion}`];
  if (meta.description) lines.push(meta.description);
  if (meta.repository) lines.push(`Repository: ${meta.repository}`);
  if (meta.homepage) lines.push(`Homepage: ${meta.homepage}`);
  if (meta.documentation) lines.push(`Docs: ${meta.documentation}`);
  lines.push(`Downloads: ${meta.downloads.toLocaleString()}`);

  if (rustdoc) {
    lines.push(`\n## Crate docs\n${truncate(rustdoc.rootDocs, 4000)}`);
    const kindLines: string[] = [];
    for (const [kind, names] of Object.entries(rustdoc.topLevel)) {
      if (!names.length) continue;
      const label = KIND_LABELS[kind] ?? `${kind}s`;
      kindLines.push(`${label}: ${names.join(", ")}`);
    }
    if (kindLines.length) lines.push(`\n## Top-level items\n${kindLines.join("\n")}`);
  } else {
    lines.push(
      `\n(Structured rustdoc JSON not available for this version — browse https://docs.rs/${meta.name}/${version}/${meta.name}/)`,
    );
  }
  return lines.join("\n");
}

export function formatItem(
  crate: string,
  version: string,
  hit: ItemHit,
  body: ItemBody,
  docs: string,
  deprecated?: string | null,
  deprecatedSince?: string | null,
): string {
  const lines = [`${hit.path}  (${hit.kind})`];
  if (deprecated) {
    const since = deprecatedSince ? ` since ${deprecatedSince}` : "";
    lines.push(`[deprecated${since}: ${deprecated}]`);
  }
  lines.push("");
  if (body.signature) {
    lines.push(body.signature);
    lines.push("");
  }
  lines.push(truncate(docs, 6000));
  if (body.members.length) {
    lines.push("");
    lines.push("Members:");
    for (const m of body.members) lines.push(`- ${m.name} — ${m.summary}`);
  }
  lines.push(`Full docs: https://docs.rs/${crate}/${version}/`);
  return lines.join("\n");
}

export function formatItemNotFound(crate: string, query: string, suggestions: string[]): string {
  const head = `No item "${query}" in ${crate}.`;
  if (!suggestions.length) return `${head} No close matches.`;
  return `${head}\nClosest matches:\n${suggestions.map((s) => `- ${s}`).join("\n")}`;
}

export function formatMembers(
  crate: string,
  version: string,
  hit: ItemHit,
  members: MemberInfo[],
): string {
  const lines = [`Members of ${hit.path} (${hit.kind}):`];
  const byKind: Record<string, MemberInfo[]> = {};
  for (const m of members) (byKind[m.kind] ??= []).push(m);

  for (const [kind, items] of Object.entries(byKind)) {
    const label = KIND_LABELS[kind] ?? `${kind}s`;
    lines.push(`\n${label}:`);
    for (const m of items) {
      let line = `  ${m.name}`;
      if (m.signature) line += `\n    ${m.signature.replace(/\n/g, "\n    ")}`;
      if (m.deprecated) {
        const since = m.deprecatedSince ? ` (since ${m.deprecatedSince})` : "";
        line += `  [deprecated${since}]`;
      }
      if (m.summary) line += `\n    — ${m.summary}`;
      lines.push(line);
    }
  }
  lines.push(`\nFull docs: https://docs.rs/${crate}/${version}/`);
  return lines.join("\n");
}
