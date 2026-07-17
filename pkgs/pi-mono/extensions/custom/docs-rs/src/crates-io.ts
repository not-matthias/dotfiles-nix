/**
 * crates.io REST client. Dependency-free (global fetch, node built-ins only).
 * crates.io rejects requests without a descriptive User-Agent with 403, so
 * every request must send one.
 */

const UA = "omp-docs-rs-extension (https://github.com/not-matthias/dotfiles-nix)";

async function getJson(url: string): Promise<unknown> {
  const res = await fetch(url, {
    headers: { "User-Agent": UA, Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`crates.io ${res.status} for ${url}`);
  return res.json();
}

// Shapes of the crates.io responses we consume; validated shallowly at the
// boundary via `as`, then read defensively with `?? fallback`.
interface CratesSearchResponse {
  meta?: { total?: number };
  crates?: {
    name: string;
    max_stable_version?: string;
    newest_version?: string;
    description?: string;
    downloads?: number;
  }[];
}

interface CrateResponse {
  crate?: {
    name: string;
    description?: string;
    max_stable_version?: string;
    newest_version?: string;
    repository?: string;
    homepage?: string;
    documentation?: string;
    downloads?: number;
  };
}

export interface CrateSearchResult {
  total: number;
  crates: {
    name: string;
    version: string;
    description: string;
    downloads: number;
  }[];
}

export async function searchCrates(
  query: string,
  limit: number,
): Promise<CrateSearchResult> {
  const url = `https://crates.io/api/v1/crates?q=${encodeURIComponent(query)}&per_page=${limit}`;
  // boundary: external JSON, read defensively below.
  const data = (await getJson(url)) as CratesSearchResponse;
  const crates = (data.crates ?? []).map((c) => ({
    name: c.name,
    version: c.max_stable_version ?? c.newest_version ?? "",
    description: c.description ?? "",
    downloads: c.downloads ?? 0,
  }));
  return { total: data.meta?.total ?? crates.length, crates };
}

export interface CrateMeta {
  name: string;
  description: string;
  stableVersion: string;
  newestVersion: string;
  repository?: string;
  homepage?: string;
  documentation?: string;
  downloads: number;
}

export async function crateMeta(name: string): Promise<CrateMeta> {
  const url = `https://crates.io/api/v1/crates/${encodeURIComponent(name)}`;
  // boundary: external JSON, read defensively below.
  const data = (await getJson(url)) as CrateResponse;
  const c = data.crate ?? { name };
  return {
    name: c.name,
    description: c.description ?? "",
    stableVersion: c.max_stable_version ?? c.newest_version ?? "",
    newestVersion: c.newest_version ?? "",
    repository: c.repository ?? undefined,
    homepage: c.homepage ?? undefined,
    documentation: c.documentation ?? undefined,
    downloads: c.downloads ?? 0,
  };
}
