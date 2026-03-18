import Link from 'next/link';

export default function Navbar() {
  const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://app.gwangmeu.com';

  return (
    <nav className="sticky top-0 z-50 bg-dark-bg/90 backdrop-blur-md border-b border-dark-border">
      <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 group">
          <div className="w-8 h-8 rounded-lg bg-gold/10 border border-gold/30 flex items-center justify-center">
            <span className="text-gold font-display font-bold text-sm">G</span>
          </div>
          <span className="font-display font-bold text-lg tracking-wider text-gold group-hover:text-gold-light transition-colors">
            GWANG MEU
          </span>
        </Link>

        {/* Navigation */}
        <div className="hidden md:flex items-center gap-6 text-sm text-text-secondary">
          <Link href="/villages" className="hover:text-text-primary transition-colors">
            Villages
          </Link>
          <Link href="/a-propos" className="hover:text-text-primary transition-colors">
            À propos
          </Link>
        </div>

        {/* CTA */}
        <a
          href={appUrl}
          className="btn-gold text-sm px-5 py-2"
          target="_blank"
          rel="noopener noreferrer"
        >
          Rejoindre l&apos;app →
        </a>
      </div>
    </nav>
  );
}
