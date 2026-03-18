import type { Metadata } from 'next';
import { Fraunces, Plus_Jakarta_Sans } from 'next/font/google';
import './globals.css';

const fraunces = Fraunces({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
});

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://gwangmeu.com'),
  title: {
    default: 'GWANG MEU - Patrimoine Culturel Africain',
    template: '%s | GWANG MEU',
  },
  description:
    'Plateforme de préservation culturelle africaine. Découvrez les villages, langues, traditions et généalogies de l\'Afrique. Langues · Culture · Futur.',
  keywords: ['Afrique', 'culture africaine', 'villages africains', 'patrimoine', 'diaspora', 'langues africaines'],
  authors: [{ name: 'GWANG MEU' }],
  openGraph: {
    type: 'website',
    locale: 'fr_FR',
    siteName: 'GWANG MEU',
    images: [{ url: '/og/default.jpg', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    site: '@gwangmeu',
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className={`${fraunces.variable} ${plusJakarta.variable}`}>
      <body className="bg-dark-bg text-text-primary font-sans antialiased">
        {children}
      </body>
    </html>
  );
}
