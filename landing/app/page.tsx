import type { Metadata } from 'next';
import { fetchPublicStats } from '@/lib/api';
import HeroSection from '@/components/ui/HeroSection';
import Navbar from '@/components/ui/Navbar';
import Footer from '@/components/ui/Footer';

export const metadata: Metadata = {
  title: 'GWANG MEU - Patrimoine Culturel Africain',
  description: 'Rejoignez la plateforme communautaire qui connecte les populations africaines et leur diaspora. Préservez les langues, villages et traditions.',
};

export const revalidate = 3600;

const FEATURES = [
  {
    icon: '🗺️',
    title: 'Villages documentés',
    description: 'Chaque village avec sa carte interactive, son histoire, ses rites et son patrimoine culturel.',
  },
  {
    icon: '🌳',
    title: 'Généalogie familiale',
    description: 'Reconstructez votre arbre généalogique et retrouvez vos origines grâce à l\'IA.',
  },
  {
    icon: '🗣️',
    title: 'Langues & Dialectes',
    description: 'Apprenez ou enseignez votre langue maternelle avec des cours interactifs et quiz IA.',
  },
  {
    icon: '🎥',
    title: 'Lives culturels',
    description: 'Conférences, cours en direct et visites virtuelles de villages africains.',
  },
  {
    icon: '🤖',
    title: 'Guide IA (Claude)',
    description: 'Votre guide culturel personnel powered by Claude Anthropic, répondant en votre langue.',
  },
  {
    icon: '🌍',
    title: 'Diaspora connectée',
    description: 'Reliez la diaspora mondiale aux racines africaines par la culture et les liens familiaux.',
  },
];

export default async function HomePage() {
  const stats = await fetchPublicStats();

  return (
    <>
      <Navbar />
      <main>
        <HeroSection stats={stats} />

        {/* Features */}
        <section className="py-24 px-4 max-w-7xl mx-auto">
          <h2 className="section-title text-center mb-4">
            Tout ce dont votre culture a besoin
          </h2>
          <p className="text-text-secondary text-center mb-16 max-w-2xl mx-auto">
            Une plateforme complète pour préserver, partager et transmettre le patrimoine culturel africain aux générations futures.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {FEATURES.map((feature) => (
              <div key={feature.title} className="card p-6 hover:border-gold/40 transition-colors">
                <div className="text-4xl mb-4">{feature.icon}</div>
                <h3 className="text-lg font-semibold text-text-primary mb-2">{feature.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed">{feature.description}</p>
              </div>
            ))}
          </div>
        </section>

        {/* CTA final */}
        <section className="py-24 px-4 text-center">
          <div className="max-w-2xl mx-auto">
            <h2 className="section-title mb-6">Rejoignez la communauté</h2>
            <p className="text-text-secondary mb-10 text-lg">
              {stats.villages} villages · {stats.members.toLocaleString('fr')} membres · Gratuit pour toujours
            </p>
            <a
              href={process.env.NEXT_PUBLIC_APP_URL || 'https://app.gwouangmeu.com'}
              className="btn-gold text-lg px-10 py-4 inline-block"
            >
              Commencer gratuitement →
            </a>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
