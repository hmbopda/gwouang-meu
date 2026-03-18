import Image from 'next/image';
import Link from 'next/link';
import type { Village } from '@/lib/types';
import { villageSlug } from '@/lib/types';

interface VillageCardProps {
  village: Village;
}

export default function VillageCard({ village }: VillageCardProps) {
  const slug = villageSlug(village);

  return (
    <Link href={`/villages/${slug}`} className="card group hover:border-gold/40 transition-colors block">
      {/* Image */}
      <div className="relative aspect-video overflow-hidden bg-dark-alt">
        {village.coverImageUrl ? (
          <Image
            src={village.coverImageUrl}
            alt={`Village de ${village.name}`}
            fill
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center text-text-hint">
            <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
            </svg>
          </div>
        )}

        {/* Badge vérifié */}
        {village.verified && (
          <div className="absolute top-2 right-2 bg-gold text-black text-xs font-semibold px-2 py-0.5 rounded-full">
            ✓ Vérifié
          </div>
        )}
      </div>

      {/* Contenu */}
      <div className="p-4">
        <h3 className="font-semibold text-text-primary group-hover:text-gold transition-colors truncate">
          {village.name}
        </h3>

        <div className="flex items-center gap-1 mt-1 text-text-secondary text-sm">
          <span>{village.country}</span>
          {village.primaryDialect && (
            <>
              <span>·</span>
              <span>{village.primaryDialect}</span>
            </>
          )}
        </div>

        {village.description && (
          <p className="text-text-hint text-sm mt-2 line-clamp-2">{village.description}</p>
        )}

        <div className="flex items-center gap-1 mt-3 text-text-secondary text-sm">
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span>{village.memberCount} membres</span>
        </div>
      </div>
    </Link>
  );
}
