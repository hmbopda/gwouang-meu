import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Image from 'next/image';
import { fetchAllVillageSlugs, fetchVillageBySlug } from '@/lib/api';
import { villageSlug } from '@/lib/types';
import { VillageJsonLd } from '@/components/seo/JsonLd';
import Navbar from '@/components/ui/Navbar';
import Footer from '@/components/ui/Footer';

interface Props {
  params: { slug: string };
}

// ── SSG : génère toutes les pages village au build ────────────────────────────

export async function generateStaticParams() {
  const slugs = await fetchAllVillageSlugs();
  return slugs.map(({ slug }) => ({ slug }));
}

// ── SEO dynamique par village ─────────────────────────────────────────────────

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const village = await fetchVillageBySlug(params.slug);
  if (!village) return { title: 'Village introuvable' };

  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://gwouangmeu.com';

  return {
    title: `${village.name} — Histoire et Culture`,
    description:
      village.description ||
      `Découvrez le village de ${village.name} (${village.country}) sur GWANG MEU. Histoire, culture, dialectes et communauté.`,
    openGraph: {
      title: `${village.name} | GWANG MEU`,
      description: village.description,
      url: `${siteUrl}/villages/${params.slug}`,
      images: village.coverImageUrl ? [{ url: village.coverImageUrl }] : [],
    },
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

export const revalidate = 3600;

export default async function VillageDetailPage({ params }: Props) {
  const village = await fetchVillageBySlug(params.slug);
  if (!village) notFound();

  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://gwouangmeu.com';
  const pageUrl = `${siteUrl}/villages/${params.slug}`;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://app.gwouangmeu.com';

  return (
    <>
      <VillageJsonLd village={village} url={pageUrl} />
      <Navbar />

      <main>
        {/* Hero image */}
        <div className="relative h-[50vh] min-h-[320px] bg-dark-alt">
          {village.coverImageUrl ? (
            <Image
              src={village.coverImageUrl}
              alt={`Village de ${village.name}`}
              fill
              priority
              className="object-cover"
              sizes="100vw"
            />
          ) : (
            <div className="absolute inset-0 bg-gradient-to-b from-dark-surface to-dark-bg" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-dark-bg via-dark-bg/40 to-transparent" />
          <div className="absolute bottom-8 left-0 right-0 px-4 max-w-4xl mx-auto">
            <h1 className="font-display text-4xl md:text-6xl font-bold text-white mb-2">
              {village.name}
            </h1>
            <div className="flex flex-wrap gap-3 text-text-secondary text-sm">
              <span>🏳 {village.country}</span>
              {village.region && <span>📍 {village.region}</span>}
              {village.primaryDialect && <span>🗣️ {village.primaryDialect}</span>}
            </div>
          </div>
        </div>

        <div className="max-w-4xl mx-auto px-4 py-12 space-y-12">
          {/* Stats */}
          <div className="grid grid-cols-3 gap-6 p-6 card">
            <div className="text-center">
              <p className="font-display text-2xl font-bold text-gold">{village.memberCount}</p>
              <p className="text-text-secondary text-sm">Membres</p>
            </div>
            {village.populationEstimate && (
              <div className="text-center">
                <p className="font-display text-2xl font-bold text-gold">
                  {village.populationEstimate.toLocaleString('fr')}
                </p>
                <p className="text-text-secondary text-sm">Habitants</p>
              </div>
            )}
            {village.foundedYear && (
              <div className="text-center">
                <p className="font-display text-2xl font-bold text-gold">{village.foundedYear}</p>
                <p className="text-text-secondary text-sm">Fondé en</p>
              </div>
            )}
          </div>

          {/* Description */}
          {village.description && (
            <section>
              <h2 className="font-display text-2xl font-bold mb-4">À propos</h2>
              <p className="text-text-secondary leading-relaxed">{village.description}</p>
            </section>
          )}

          {/* Histoire */}
          {village.historicalSummary && (
            <section>
              <h2 className="font-display text-2xl font-bold mb-4">Histoire</h2>
              <div className="prose prose-invert prose-gold max-w-none">
                <p className="text-text-secondary leading-relaxed">{village.historicalSummary}</p>
              </div>
            </section>
          )}

          {/* CTA */}
          <section className="card p-8 text-center">
            <h2 className="font-display text-2xl font-bold mb-3">
              Vous êtes de {village.name} ?
            </h2>
            <p className="text-text-secondary mb-6">
              Rejoignez la communauté, partagez votre histoire et connectez-vous avec d&apos;autres membres.
            </p>
            <a href={appUrl} className="btn-gold text-base px-8 py-3 inline-block">
              Rejoindre le village →
            </a>
          </section>
        </div>
      </main>

      <Footer />
    </>
  );
}
