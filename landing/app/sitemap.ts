import type { MetadataRoute } from 'next';
import { fetchAllVillageSlugs, fetchCountries, fetchContinents } from '@/lib/api';

const BASE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'https://gwangmeu.com';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [villageSlugs, continents] = await Promise.all([
    fetchAllVillageSlugs(),
    fetchContinents(),
  ]);

  const villagePaths: MetadataRoute.Sitemap = villageSlugs.map(({ slug }) => ({
    url: `${BASE_URL}/villages/${slug}`,
    lastModified: new Date(),
    changeFrequency: 'weekly',
    priority: 0.8,
  }));

  const countryPaths: MetadataRoute.Sitemap = continents.flatMap((c) =>
    Array.from({ length: c.countryCount }).map((_, i) => ({
      url: `${BASE_URL}/pays/`,
      lastModified: new Date(),
      changeFrequency: 'monthly' as const,
      priority: 0.6,
    }))
  );

  return [
    { url: BASE_URL, lastModified: new Date(), changeFrequency: 'daily', priority: 1.0 },
    { url: `${BASE_URL}/villages`, lastModified: new Date(), changeFrequency: 'daily', priority: 0.9 },
    { url: `${BASE_URL}/a-propos`, lastModified: new Date(), changeFrequency: 'monthly', priority: 0.4 },
    ...villagePaths,
  ];
}
