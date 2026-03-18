import type { Metadata } from 'next';
import Navbar from '@/components/ui/Navbar';
import Footer from '@/components/ui/Footer';

export const metadata: Metadata = {
  title: 'À propos de GWANG MEU',
  description: 'GWANG MEU est une plateforme de préservation culturelle africaine fondée pour connecter les communautés à leurs racines. Langues · Culture · Futur.',
};

const TEAM_VALUES = [
  {
    icon: '🌍',
    title: 'Authenticité',
    description: 'Chaque contenu est validé par des membres de la communauté locale avant publication.',
  },
  {
    icon: '🔒',
    title: 'Confidentialité',
    description: 'Les données familiales sensibles (géolocalisation, généalogie) sont chiffrées et protégées par RLS Supabase.',
  },
  {
    icon: '🤝',
    title: 'Communauté',
    description: 'La plateforme appartient aux communautés. Chaque village est géré par ses propres ambassadeurs.',
  },
  {
    icon: '🤖',
    title: 'IA responsable',
    description: 'Claude AI enrichit le contenu culturel avec validation humaine obligatoire avant tout enregistrement.',
  },
];

export default function AboutPage() {
  return (
    <>
      <Navbar />
      <main className="max-w-4xl mx-auto px-4 py-16">
        {/* Hero */}
        <div className="text-center mb-20">
          <p className="text-gold font-semibold tracking-widest mb-4 uppercase text-sm">Notre mission</p>
          <h1 className="section-title mb-6">
            Préserver la culture africaine pour les générations futures
          </h1>
          <p className="text-text-secondary text-lg leading-relaxed">
            GWANG MEU (anciennement NGOMALA.ACADEMY) est une plateforme communautaire fondée pour
            connecter les populations africaines locales et leur diaspora mondiale à travers la culture,
            la langue et les liens familiaux.
          </p>
        </div>

        {/* Mission */}
        <section className="mb-20">
          <h2 className="font-display text-2xl font-bold mb-6">Pourquoi GWANG MEU ?</h2>
          <div className="space-y-4 text-text-secondary leading-relaxed">
            <p>
              Des milliers de langues africaines sont menacées d&apos;extinction. Des villages entiers
              voient leur histoire s&apos;effacer à mesure que les anciens disparaissent. La diaspora
              africaine, éparpillée aux quatre coins du monde, perd progressivement le fil de ses origines.
            </p>
            <p>
              GWANG MEU répond à ces défis avec la technologie moderne : intelligence artificielle,
              cartographie interactive, arbres généalogiques numériques et cours de langues en direct.
            </p>
          </div>
        </section>

        {/* Valeurs */}
        <section className="mb-20">
          <h2 className="font-display text-2xl font-bold mb-8">Nos valeurs</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {TEAM_VALUES.map((v) => (
              <div key={v.title} className="card p-6">
                <div className="text-3xl mb-3">{v.icon}</div>
                <h3 className="font-semibold text-text-primary mb-2">{v.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed">{v.description}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Stack technique (pour les développeurs) */}
        <section>
          <h2 className="font-display text-2xl font-bold mb-6">La technologie derrière</h2>
          <div className="card p-6">
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm text-text-secondary">
              {[
                'Spring Boot Modulith', 'Flutter (iOS/Android/Web)', 'Next.js 14 (SEO)',
                'Supabase (Auth + DB)', 'Neo4j (Généalogie)', 'Claude Anthropic (IA)',
                'PostGIS (Cartographie)', 'LiveKit (Lives)', 'Meilisearch (Recherche)',
              ].map((tech) => (
                <div key={tech} className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-gold flex-shrink-0" />
                  {tech}
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
