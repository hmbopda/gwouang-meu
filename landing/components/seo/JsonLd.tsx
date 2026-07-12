import type { Village } from '@/lib/types';

interface VillageJsonLdProps {
  village: Village;
  url: string;
}

export function VillageJsonLd({ village, url }: VillageJsonLdProps) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Place',
    name: village.name,
    description: village.description,
    url,
    address: {
      '@type': 'PostalAddress',
      addressCountry: village.country,
      addressRegion: village.region,
    },
    ...(village.latitude && village.longitude
      ? {
          geo: {
            '@type': 'GeoCoordinates',
            latitude: village.latitude,
            longitude: village.longitude,
          },
        }
      : {}),
    ...(village.foundedYear
      ? { foundingDate: village.foundedYear.toString() }
      : {}),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}

export function WebsiteJsonLd() {
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://gwouangmeu.com';
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'GWANG MEU',
    description: 'Patrimoine Culturel Africain — Langues · Culture · Futur',
    url: siteUrl,
    potentialAction: {
      '@type': 'SearchAction',
      target: `${siteUrl}/villages?q={search_term_string}`,
      'query-input': 'required name=search_term_string',
    },
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}
