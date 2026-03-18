import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { fetchCountry, fetchVillages } from '@/lib/api';
import VillageCard from '@/components/ui/VillageCard';
import Navbar from '@/components/ui/Navbar';
import Footer from '@/components/ui/Footer';

interface Props {
  params: { code: string };
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const country = await fetchCountry(params.code.toUpperCase());
  if (!country) return { title: 'Pays introuvable' };

  return {
    title: `Villages de ${country.name}`,
    description: `Découvrez les ${country.villageCount} villages de ${country.name} documentés sur GWANG MEU. Culture, histoire et communautés.`,
  };
}

export const revalidate = 3600;

export default async function CountryPage({ params }: Props) {
  const [country, villages] = await Promise.all([
    fetchCountry(params.code.toUpperCase()),
    fetchVillages({ countryCode: params.code.toUpperCase() }),
  ]);

  if (!country) notFound();

  return (
    <>
      <Navbar />
      <main className="max-w-7xl mx-auto px-4 py-12">
        {/* En-tête */}
        <div className="mb-12">
          <div className="flex items-center gap-4 mb-4">
            {country.flagEmoji && (
              <span className="text-5xl" aria-hidden>{country.flagEmoji}</span>
            )}
            <div>
              <h1 className="section-title">{country.name}</h1>
              <p className="text-text-secondary mt-1">{country.villageCount} villages documentés</p>
            </div>
          </div>
        </div>

        {/* Villages */}
        {villages.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {villages.map((village) => (
              <VillageCard key={village.id} village={village} />
            ))}
          </div>
        ) : (
          <div className="text-center py-24 text-text-secondary">
            <p className="text-5xl mb-4">🏘️</p>
            <p>Aucun village documenté pour l&apos;instant.</p>
          </div>
        )}
      </main>
      <Footer />
    </>
  );
}
