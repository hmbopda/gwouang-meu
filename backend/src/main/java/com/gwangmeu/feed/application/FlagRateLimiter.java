package com.gwangmeu.feed.application;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate limiter Bucket4j (in-memory) pour l'endpoint POST /flag.
 * Limite : 3 signalements par utilisateur par heure.
 *
 * Note : pour un deploiement multi-instances, migrer vers bucket4j-redis.
 */
@Component
public class FlagRateLimiter {

    private static final int MAX_FLAGS_PER_HOUR = 3;
    private final ConcurrentHashMap<UUID, Bucket> buckets = new ConcurrentHashMap<>();

    /**
     * @return true si la requete est autorisee, false si le quota est depasse
     */
    public boolean tryConsume(UUID userId) {
        Bucket bucket = buckets.computeIfAbsent(userId, this::newBucket);
        return bucket.tryConsume(1);
    }

    private Bucket newBucket(UUID userId) {
        Bandwidth limit = Bandwidth.classic(
                MAX_FLAGS_PER_HOUR,
                Refill.intervally(MAX_FLAGS_PER_HOUR, Duration.ofHours(1))
        );
        return Bucket.builder().addLimit(limit).build();
    }
}
