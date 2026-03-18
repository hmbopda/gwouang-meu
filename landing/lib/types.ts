// ── Types du domaine GWANG MEU ────────────────────────────────────────────────

export interface Village {
  id: string;
  name: string;
  description?: string;
  country: string;
  region?: string;
  continentCode?: string;
  coverImageUrl?: string;
  latitude?: number;
  longitude?: number;
  primaryDialect?: string;
  memberCount: number;
  verified: boolean;
  foundedYear?: number;
  populationEstimate?: number;
  historicalSummary?: string;
  createdAt?: string;
}

export interface Country {
  id: string;
  isoCode: string;
  name: string;
  continentCode: string;
  flagEmoji?: string;
  flagUrl?: string;
  villageCount: number;
}

export interface Continent {
  id: string;
  code: string;
  name: string;
  nameFr?: string;
  description?: string;
  coverImageUrl?: string;
  countryCount: number;
  villageCount: number;
}

export interface GeoSearchResult {
  id?: string;
  type: 'CONTINENT' | 'COUNTRY' | 'VILLAGE';
  name: string;
  code?: string;
  parentName?: string;
  imageUrl?: string;
  latitude?: number;
  longitude?: number;
}

// ── Wrapper API ───────────────────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message: string;
  status: number;
  timestamp: string;
}

export interface PageData<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}

// ── Utilitaires ───────────────────────────────────────────────────────────────

export function villageSlug(village: Village): string {
  return village.name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}
