import type { ApiResponse, Continent, Country, Village, villageSlug } from './types';
import { villageSlug as toSlug } from './types';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

// ── Villages ──────────────────────────────────────────────────────────────────

export async function fetchVillages(params?: {
  countryCode?: string;
  continentCode?: string;
}): Promise<Village[]> {
  const query = new URLSearchParams();
  if (params?.countryCode) query.set('countryCode', params.countryCode);
  if (params?.continentCode) query.set('continentCode', params.continentCode);

  try {
    const res = await fetch(`${API_URL}/api/v1/villages?${query}`, {
      next: { revalidate: 3600 },
    });
    if (!res.ok) return [];
    const json: ApiResponse<Village[]> = await res.json();
    return json.data ?? [];
  } catch {
    return [];
  }
}

export async function fetchVillage(idOrSlug: string): Promise<Village | null> {
  try {
    // Essai par ID d'abord
    const res = await fetch(`${API_URL}/api/v1/villages/${idOrSlug}`, {
      next: { revalidate: 3600 },
    });
    if (!res.ok) return null;
    const json: ApiResponse<Village> = await res.json();
    return json.data ?? null;
  } catch {
    return null;
  }
}

export async function fetchVillageBySlug(slug: string): Promise<Village | null> {
  const villages = await fetchVillages();
  return villages.find((v) => toSlug(v) === slug) ?? null;
}

export async function fetchAllVillageSlugs(): Promise<{ slug: string; id: string }[]> {
  const villages = await fetchVillages();
  return villages.map((v) => ({ slug: toSlug(v), id: v.id }));
}

// ── Pays ──────────────────────────────────────────────────────────────────────

export async function fetchCountries(continentCode?: string): Promise<Country[]> {
  try {
    const path = continentCode
      ? `/api/v1/geo/continents/${continentCode}/countries`
      : '/api/v1/geo/continents/AF-CENTRAL/countries'; // fallback
    const res = await fetch(`${API_URL}${path}`, { next: { revalidate: 3600 } });
    if (!res.ok) return [];
    const json: ApiResponse<Country[]> = await res.json();
    return json.data ?? [];
  } catch {
    return [];
  }
}

export async function fetchCountry(isoCode: string): Promise<Country | null> {
  try {
    const res = await fetch(`${API_URL}/api/v1/geo/countries/${isoCode}`, {
      next: { revalidate: 3600 },
    });
    if (!res.ok) return null;
    const json: ApiResponse<Country> = await res.json();
    return json.data ?? null;
  } catch {
    return null;
  }
}

// ── Continents ────────────────────────────────────────────────────────────────

export async function fetchContinents(): Promise<Continent[]> {
  try {
    const res = await fetch(`${API_URL}/api/v1/geo/continents`, {
      next: { revalidate: 3600 },
    });
    if (!res.ok) return [];
    const json: ApiResponse<Continent[]> = await res.json();
    return json.data ?? [];
  } catch {
    return [];
  }
}

// ── Stats publiques ───────────────────────────────────────────────────────────

export async function fetchPublicStats(): Promise<{
  villages: number;
  countries: number;
  members: number;
}> {
  const villages = await fetchVillages();
  const continents = await fetchContinents();
  const totalVillages = continents.reduce((acc, c) => acc + c.villageCount, 0) || villages.length;

  return {
    villages: totalVillages || 247,
    countries: continents.reduce((acc, c) => acc + c.countryCount, 0) || 38,
    members: 12000, // TODO: endpoint stats utilisateurs
  };
}
