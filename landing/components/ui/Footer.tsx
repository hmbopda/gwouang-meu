import Link from 'next/link';

const LINKS = {
  Plateforme: [
    { label: 'Villages', href: '/villages' },
    { label: 'À propos', href: '/a-propos' },
    { label: 'Rejoindre l\'app', href: process.env.NEXT_PUBLIC_APP_URL || 'https://app.gwouangmeu.com' },
  ],
  Légal: [
    { label: 'Confidentialité', href: '/confidentialite' },
    { label: 'Conditions', href: '/conditions' },
    { label: 'Cookies', href: '/cookies' },
  ],
};

export default function Footer() {
  return (
    <footer className="border-t border-dark-border bg-dark-surface mt-24">
      <div className="max-w-7xl mx-auto px-4 py-16">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          {/* Brand */}
          <div className="md:col-span-2">
            <p className="font-display font-bold text-xl text-gold tracking-widest mb-3">GWANG MEU</p>
            <p className="text-text-secondary text-sm leading-relaxed max-w-xs">
              Plateforme de préservation culturelle africaine. Langues · Culture · Futur.
            </p>
            {/* Réseaux sociaux */}
            <div className="flex gap-4 mt-6">
              {['Twitter', 'Instagram', 'YouTube'].map((s) => (
                <span key={s} className="text-text-hint hover:text-gold cursor-pointer transition-colors text-sm">
                  {s}
                </span>
              ))}
            </div>
          </div>

          {/* Liens */}
          {Object.entries(LINKS).map(([section, links]) => (
            <div key={section}>
              <h3 className="text-text-primary font-semibold mb-4 text-sm uppercase tracking-wider">
                {section}
              </h3>
              <ul className="space-y-2">
                {links.map((link) => (
                  <li key={link.label}>
                    <Link
                      href={link.href}
                      className="text-text-secondary hover:text-text-primary text-sm transition-colors"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="border-t border-dark-border pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-text-hint text-sm">
            © {new Date().getFullYear()} GWANG MEU. Tous droits réservés.
          </p>
          <p className="text-text-hint text-xs">
            Fait avec ❤️ pour l&apos;Afrique et sa diaspora
          </p>
        </div>
      </div>
    </footer>
  );
}
