import Link from 'next/link';

interface HeroSectionProps {
  stats: { villages: number; countries: number; members: number };
}

export default function HeroSection({ stats }: HeroSectionProps) {
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://app.gwangmeu.com';

  return (
    <section className="relative min-h-[90vh] flex items-center justify-center px-4 overflow-hidden">
      {/* Arrière-plan décoratif */}
      <div className="absolute inset-0 bg-gradient-dark" aria-hidden />
      <div
        className="absolute inset-0 opacity-5"
        style={{
          backgroundImage: 'radial-gradient(circle at 50% 50%, #C8A020 0%, transparent 70%)',
        }}
        aria-hidden
      />

      <div className="relative max-w-4xl mx-auto text-center animate-fade-in">
        {/* Badge */}
        <div className="inline-flex items-center gap-2 bg-gold/10 border border-gold/20 rounded-full px-4 py-2 mb-8 text-sm text-gold">
          <span className="w-2 h-2 rounded-full bg-gold animate-pulse" />
          Préservation culturelle africaine
        </div>

        {/* Titre */}
        <h1 className="font-display text-5xl md:text-7xl font-bold text-text-primary mb-6 leading-tight">
          Votre héritage{' '}
          <span className="text-gold">africain</span>,{' '}
          <br className="hidden md:block" />
          préservé pour l&apos;éternité
        </h1>

        {/* Sous-titre */}
        <p className="text-text-secondary text-xl md:text-2xl mb-12 max-w-2xl mx-auto leading-relaxed">
          Connectez-vous à vos racines. Explorez les villages, apprenez les langues et partagez la richesse culturelle africaine avec votre famille.
        </p>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center mb-20">
          <a href={appUrl} className="btn-gold text-lg px-8 py-4">
            Rejoindre gratuitement
          </a>
          <Link href="/villages" className="btn-outline-gold text-lg px-8 py-4">
            Explorer les villages
          </Link>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-8 max-w-lg mx-auto">
          <div>
            <p className="font-display text-3xl font-bold text-gold">{stats.villages}+</p>
            <p className="text-text-secondary text-sm mt-1">Villages</p>
          </div>
          <div>
            <p className="font-display text-3xl font-bold text-gold">{stats.countries}+</p>
            <p className="text-text-secondary text-sm mt-1">Langues</p>
          </div>
          <div>
            <p className="font-display text-3xl font-bold text-gold">
              {(stats.members / 1000).toFixed(0)}K+
            </p>
            <p className="text-text-secondary text-sm mt-1">Membres</p>
          </div>
        </div>
      </div>
    </section>
  );
}
