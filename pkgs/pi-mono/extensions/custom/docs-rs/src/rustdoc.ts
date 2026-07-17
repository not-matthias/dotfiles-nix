/**
 * docs.rs rustdoc-JSON client + traversal. Dependency-free (global fetch,
 * node:zlib only). Every access into the parsed doc is optional-chained /
 * guarded so a future rustdoc format bump degrades fidelity instead of
 * crashing a tool.
 */

import { gunzipSync } from "node:zlib";

export interface RustdocPath {
  crate_id?: number;
  path: string[];
  kind: string;
}

export interface RustdocItem {
  id?: number | string;
  name?: string;
  docs?: string | null;
  deprecation?: { since?: string; note?: string } | null;
  inner?: Record<string, unknown>;
}

export interface RustdocDoc {
  root: number | string;
  crate_version?: string;
  index: Record<string, RustdocItem | undefined>;
  paths: Record<string, RustdocPath | undefined>;
  format_version?: number;
}

// Narrowing helpers for the dynamically-shaped `inner` / `Type` payloads.
function rec(v: unknown): Record<string, unknown> | undefined {
  return v && typeof v === "object" && !Array.isArray(v)
    ? (v as Record<string, unknown>)
    : undefined;
}
function arr(v: unknown): unknown[] | undefined {
  return Array.isArray(v) ? v : undefined;
}
function str(v: unknown): string | undefined {
  return typeof v === "string" ? v : undefined;
}
function firstLine(s: string | null | undefined): string {
  for (const line of (s ?? "").split("\n")) {
    const t = line.trim();
    if (t) return t;
  }
  return "";
}

export async function fetchRustdoc(
  crate: string,
  version: string,
): Promise<RustdocDoc | null> {
  const url = `https://docs.rs/crate/${crate}/${version}/json.gz`;
  const res = await fetch(url);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`docs.rs ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  // boundary: gunzipped rustdoc JSON, traversed defensively below.
  return JSON.parse(gunzipSync(buf).toString("utf8")) as RustdocDoc;
}

export function topLevelItems(doc: RustdocDoc): Record<string, string[]> {
  const root = doc.index[String(doc.root)];
  const inner = rec(root?.inner);
  const mod = rec(inner?.module);
  const items = arr(mod?.items);
  if (!items) return {};
  const out: Record<string, string[]> = {};
  for (const idU of items) {
    const id = String(idU);
    const child = doc.index[id];
    const childInner = rec(child?.inner);
    const kind = doc.paths[id]?.kind ?? (childInner ? Object.keys(childInner)[0] : undefined);
    const name = child?.name;
    if (!kind || !name) continue;
    (out[kind] ??= []).push(name);
  }
  return out;
}

export function rootDocs(doc: RustdocDoc): string {
  return doc.index[String(doc.root)]?.docs ?? "";
}

export interface ItemHit {
  id: string;
  path: string;
  kind: string;
}

export interface FindResult {
  hit?: ItemHit;
  suggestions: string[];
}

// Trait methods, struct/enum inherent-impl methods, and enum variants are
// indexed in `doc.index` but absent from `doc.paths` (which only holds
// path-addressable items: modules, structs, traits, …). A query like
// `Itertools::sorted_by_key` therefore misses unless we also walk each
// path-addressable container's members and add them to the candidate list.
function kindOf(doc: RustdocDoc, id: string): string | undefined {
  const p = doc.paths[id]?.kind;
  if (p) return p;
  const inner = rec(doc.index[id]?.inner);
  return inner ? Object.keys(inner)[0] : undefined;
}

function* walkMembers(doc: RustdocDoc): Generator<{
  id: string;
  full: string;
  rel: string;
  kind: string;
}> {
  for (const [parentId, s] of Object.entries(doc.paths)) {
    if (!s || !Array.isArray(s.path)) continue;
    const parentFull = s.path.join("::");
    const parentRel = s.path.slice(1).join("::");
    const inner = rec(doc.index[parentId]?.inner);
    const trait = rec(inner?.trait);
    const en = rec(inner?.enum);
    const st = rec(inner?.struct);

    // Collect member id lists from this container: trait items, enum
    // variants, and inherent impls (struct/enum). re-uses the same shapes
    // renderItemBody already consumes.
    const idLists: unknown[][] = [];
    idLists.push(arr(trait?.items) ?? []);
    idLists.push(arr(en?.variants) ?? []);
    for (const container of [st, en]) {
      for (const implIdU of arr(container?.impls) ?? []) {
        const implInner = rec(rec(doc.index[String(implIdU)]?.inner)?.impl);
        idLists.push(arr(implInner?.items) ?? []);
      }
    }

    for (const ids of idLists) {
      for (const midU of ids) {
        const mid = String(midU);
        const mem = doc.index[mid];
        if (!mem?.name) continue;
        const kind = kindOf(doc, mid);
        if (!kind) continue;
        yield {
          id: mid,
          full: `${parentFull}::${mem.name}`,
          rel: `${parentRel}::${mem.name}`,
          kind,
        };
      }
    }
  }
}

export function findItem(doc: RustdocDoc, query: string): FindResult {
  const crateName = doc.index[String(doc.root)]?.name;
  let q = query.trim();
  if (crateName && q.startsWith(`${crateName}::`)) q = q.slice(crateName.length + 2);

  const entries: { id: string; full: string; rel: string; kind: string }[] = [];
  for (const [id, s] of Object.entries(doc.paths)) {
    if (!s || !Array.isArray(s.path)) continue;
    entries.push({
      id,
      full: s.path.join("::"),
      rel: s.path.slice(1).join("::"),
      kind: s.kind,
    });
  }
  // Members (trait methods, variants, inherent-impl methods) are not in
  // doc.paths; add them so `Parent::method` and bare `method` queries resolve.
  for (const member of walkMembers(doc)) {
    if (!doc.paths[member.id]) entries.push(member);
  }

  const qLast = (q.split("::").pop() ?? q).toLowerCase();

  const tiers: ((e: (typeof entries)[number]) => boolean)[] = [
    (e) => e.full === q || e.rel === q,
    (e) => e.full.endsWith(`::${q}`) || e.rel.endsWith(`::${q}`),
    (e) => (e.full.split("::").pop() ?? "").toLowerCase() === qLast,
  ];

  for (const match of tiers) {
    const hits = entries.filter(match);
    if (hits.length === 1) {
      const e = hits[0];
      return { hit: { id: e.id, path: e.full, kind: e.kind }, suggestions: [] };
    }
    if (hits.length > 1) break; // ambiguous → suggestions
  }

  const suggestions = [
    ...new Set(
      entries
        .filter((e) => (e.full.split("::").pop() ?? "").toLowerCase().includes(qLast))
        .map((e) => e.full),
    ),
  ]
    .sort((a, b) => a.length - b.length)
    .slice(0, 8);

  return { suggestions };
}

export interface Member {
  name: string;
  summary: string;
}

export interface ItemBody {
  signature?: string;
  members: Member[];
}

function implMethods(doc: RustdocDoc, impls: unknown[] | undefined): Member[] {
  const out: Member[] = [];
  for (const implIdU of impls ?? []) {
    const impl = doc.index[String(implIdU)];
    const im = rec(rec(impl?.inner)?.impl);
    for (const midU of arr(im?.items) ?? []) {
      const m = doc.index[String(midU)];
      const mInner = rec(m?.inner);
      if (mInner && "function" in mInner && m?.name) {
        out.push({ name: m.name, summary: firstLine(m.docs) });
      }
    }
  }
  return out;
}

export function renderItemBody(doc: RustdocDoc, hit: ItemHit): ItemBody {
  const item = doc.index[hit.id];
  const inner = rec(item?.inner);
  try {
    switch (hit.kind) {
      case "function": {
        const fn = rec(inner?.function);
        const sig = rec(fn?.sig);
        if (!sig) return { members: [] };
        const generics = rec(fn?.generics);
        const params = renderGenericParams(generics?.params);
        const inputs = (arr(sig.inputs) ?? [])
          .map((pair) => {
            const p = arr(pair);
            const n = str(p?.[0]) ?? "_";
            return `${n}: ${renderType(p?.[1])}`;
          })
          .join(", ");
        const output = sig.output ? renderType(sig.output) : "()";
        const where = renderWhereClause(generics?.where_predicates);
        let signature = `fn ${item?.name ?? ""}`;
        if (params) signature += `<${params}>`;
        signature += `(${inputs}) -> ${output}`;
        if (where) signature += `\nwhere\n${where}`;
        return { signature, members: [] };
      }
      case "struct": {
        const st = rec(inner?.struct);
        const members: Member[] = [];
        const fields = arr(rec(rec(st?.kind)?.plain)?.fields);
        for (const fidU of fields ?? []) {
          const f = doc.index[String(fidU)];
          if (f?.name) members.push({ name: f.name, summary: firstLine(f.docs) });
        }
        members.push(...implMethods(doc, arr(st?.impls)));
        return { members };
      }
      case "enum": {
        const en = rec(inner?.enum);
        const members: Member[] = [];
        for (const vidU of arr(en?.variants) ?? []) {
          const v = doc.index[String(vidU)];
          if (v?.name) members.push({ name: v.name, summary: firstLine(v.docs) });
        }
        members.push(...implMethods(doc, arr(en?.impls)));
        return { members };
      }
      case "trait": {
        const tr = rec(inner?.trait);
        const members: Member[] = [];
        for (const iidU of arr(tr?.items) ?? []) {
          const it = doc.index[String(iidU)];
          if (it?.name) members.push({ name: it.name, summary: firstLine(it.docs) });
        }
        return { members };
      }
      default:
        return { members: [] };
    }
  } catch {
    return { members: [] };
  }
}

// --- Full-signature member listing for docs_rs_members tool -------------

export interface MemberInfo {
  name: string;
  kind: string;
  signature: string | null;
  summary: string;
  deprecated: string | null;
  deprecatedSince: string | null;
}

export function listMembers(doc: RustdocDoc, hit: ItemHit): MemberInfo[] {
  const item = doc.index[hit.id];
  const inner = rec(item?.inner);
  const memberIds: string[] = [];

  switch (hit.kind) {
    case "trait": {
      const tr = rec(inner?.trait);
      for (const iidU of arr(tr?.items) ?? []) memberIds.push(String(iidU));
      break;
    }
    case "struct": {
      const st = rec(inner?.struct);
      for (const fidU of arr(rec(rec(st?.kind)?.plain)?.fields) ?? []) memberIds.push(String(fidU));
      for (const implIdU of arr(st?.impls) ?? []) {
        const implInner = rec(rec(doc.index[String(implIdU)]?.inner)?.impl);
        for (const midU of arr(implInner?.items) ?? []) memberIds.push(String(midU));
      }
      break;
    }
    case "enum": {
      const en = rec(inner?.enum);
      for (const vidU of arr(en?.variants) ?? []) memberIds.push(String(vidU));
      for (const implIdU of arr(en?.impls) ?? []) {
        const implInner = rec(rec(doc.index[String(implIdU)]?.inner)?.impl);
        for (const midU of arr(implInner?.items) ?? []) memberIds.push(String(midU));
      }
      break;
    }
  }

  return memberIds.map((id) => {
    const m = doc.index[id];
    const mInner = rec(m?.inner);
    const kind = mInner ? Object.keys(mInner)[0] : "?";
    let signature: string | null = null;
    if (kind === "function") {
      const body = renderItemBody(doc, { id, path: m?.name ?? id, kind });
      signature = body.signature ?? null;
    }
    return {
      name: m?.name ?? id,
      kind,
      signature,
      summary: firstLine(m?.docs),
      deprecated: m?.deprecation?.note ?? null,
      deprecatedSince: m?.deprecation?.since ?? null,
    };
  });
}

// --- Type/bound rendering -----------------------------------------------

function renderArgs(args: unknown): string {
  const o = rec(args);
  if (!o) return "";
  const ab = rec(o.angle_bracketed);
  if (ab) {
    const list = arr(ab?.args);
    if (!list || !list.length) return "";
    const parts = list.map((argU) => {
      const arg = rec(argU);
      if (!arg) return "_";
      if ("type" in arg) return renderType(arg.type);
      if ("lifetime" in arg) return str(arg.lifetime) ?? "'_";
      if ("const" in arg) return str(rec(arg.const)?.expr) ?? "_";
      return "_";
    });
    return `<${parts.join(", ")}>`;
  }
  const pa = rec(o.parenthesized);
  if (pa) {
    const inputs = arr(pa?.inputs) ?? [];
    const output = pa?.output ? renderType(pa.output) : "()";
    return `(${inputs.map(renderType).join(", ")}) -> ${output}`;
  }
  return "";
}

function renderBound(b: unknown): string {
  const o = rec(b);
  const tb = rec(o?.trait_bound);
  if (tb) {
    const trait = rec(tb?.trait);
    return (str(trait?.path) ?? "?") + renderArgs(trait?.args);
  }
  return str(o?.outlives) ?? "?";
}

function renderGenericParams(params: unknown): string {
  const list = arr(params) ?? [];
  const parts = list
    .map((p) => {
      const param = rec(p);
      if (!param) return undefined;
      const typeKind = rec(rec(param?.kind)?.type);
      if (typeKind?.is_synthetic) return undefined;
      const name = str(param?.name) ?? "_";
      const bounds = arr(typeKind?.bounds) ?? [];
      if (!bounds.length) return name;
      return `${name}: ${bounds.map(renderBound).join(" + ")}`;
    })
    .filter((p): p is string => p !== undefined);
  return parts.join(", ");
}

function renderWhereClause(predicates: unknown): string {
  const list = arr(predicates) ?? [];
  const lines = list
    .map((p) => {
      const o = rec(p);
      const bp = rec(o?.bound_predicate);
      if (bp) {
        const ty = renderType(bp?.type);
        const bounds = arr(bp?.bounds) ?? [];
        if (!bounds.length) return undefined;
        return `    ${ty}: ${bounds.map(renderBound).join(" + ")},`;
      }
      const lp = rec(o?.lifetime_predicate);
      if (lp) {
        const lt = str(lp?.lifetime) ?? "'_";
        const outlives = arr(lp?.outlives) ?? [];
        if (!outlives.length) return undefined;
        return `    ${lt}: ${outlives.map((x) => str(x) ?? "?").join(", ")},`;
      }
      return undefined;
    })
    .filter((l): l is string => l !== undefined);
  return lines.join("\n");
}

export function renderType(t: unknown): string {
  if (typeof t === "string") return t;
  const o = rec(t);
  if (!o) return "";
  const key = Object.keys(o)[0];
  if (!key) return "";
  const v = o[key];
  switch (key) {
    case "primitive":
      return str(v) ?? "";
    case "generic":
      return str(v) ?? "";
    case "resolved_path": {
      const rp = rec(v);
      return (str(rp?.path) ?? "") + renderArgs(rp?.args);
    }
    case "borrowed_ref": {
      const b = rec(v);
      const lt = str(b?.lifetime);
      return `&${lt ? `${lt} ` : ""}${b?.is_mutable ? "mut " : ""}${renderType(b?.type)}`;
    }
    case "raw_pointer": {
      const b = rec(v);
      return `*${b?.is_mutable ? "mut " : "const "}${renderType(b?.type)}`;
    }
    case "slice":
      return `[${renderType(v)}]`;
    case "array": {
      const b = rec(v);
      return `[${renderType(b?.type)}; ${String(b?.len)}]`;
    }
    case "tuple":
      return `(${(arr(v) ?? []).map(renderType).join(", ")})`;
    case "impl_trait":
      return `impl ${(arr(v) ?? []).map(renderBound).join(" + ")}`;
    case "dyn_trait": {
      const traits = arr(rec(v)?.traits) ?? [];
      return `dyn ${traits.map((x) => str(rec(rec(x)?.trait)?.path) ?? "?").join(" + ")}`;
    }
    case "qualified_path": {
      const d = rec(v);
      return `<${renderType(d?.self_type)} as ${str(rec(d?.trait)?.path) ?? "?"}>::${str(d?.name) ?? ""}`;
    }
    case "function_pointer":
      return "fn(..)";
    default:
      return key;
  }
}
