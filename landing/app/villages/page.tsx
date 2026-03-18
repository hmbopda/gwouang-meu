import type { Metadata } from 'next';
import { fetchVillages, fetchContinents } from '@/lib/api';
import VillageCard from '@/components/ui/VillageCard';
import Navbar from '@/components/ui/Navbar';
import Footer from '@/components/ui/Footer';

export const metadata: Metadata = {
  title: 'Découvrir les villages africains',
  description: 'Explorez des centaines de villages africains avec leur histoire, culture, dialectes et patrimoine. Rejoignez la communauté GWANG MEU.',
  openGraph: { title: 'Villages africains | GWANG MEU' },
};

export const revalidate = 3600;

export default async function VillagesPage() {
  const [villages, continents] = await Promise.all([
    fetchVillages(),
    fetchContinents(),
  ]);

  return (
    <>
      <Navbar />
      <main className="max-w-7xl mx-auto px-4 py-12">
        {/* En-tête */}
        <div className="mb-12">
          <h1 className="section-title mb-4">Villages africains</h1>
          <p className="text-text-secondary text-lg max-w-2xl">
            Explorez {villages.length || '247+'} villages documentés à travers l&apos;Afrique.
            Chaque village raconte une histoire unique.
          </p>
        </div>

        {/* Stats continents */}
        {continents.length > 0 && (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-12">
            {continents.map((c) => (
              <div key={c.code} className="card p-4 text-center">
                <p className="text-gold font-display text-2xl font-bold">{c.villageCount}</p>
                <p className="text-text-secondary text-sm mt-1">{c.name}</p>
              </div>
            ))}
          </div>
        )}

        {/* Grille villages */}
        {villages.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {villages.map((village) => (
              <VillageCard key={village.id} village={village} />
            ))}
          </div>
        ) : (
          <div className="text-center py-24 text-text-secondary">
            <p className="text-5xl mb-4">🏘️</p>
            <p className="text-lg">Les villages arrivent bientôt...</p>
          </div>
        )}
      </main>
      <Footer />
    </>
  );
}
