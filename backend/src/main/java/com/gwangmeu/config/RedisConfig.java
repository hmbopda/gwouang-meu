package com.gwangmeu.config;

import io.lettuce.core.ClientOptions;
import io.lettuce.core.SslOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.net.URI;

/**
 * Configuration Redis (Upstash).
 * Supporte les URLs rediss:// (SSL/TLS) d'Upstash en production
 * et redis:// (plain) en developpement local.
 * Utilise pour : cache sessions, Pub/Sub chat (Phase 3), rate limiting (Bucket4j).
 */
@Configuration
public class RedisConfig {

    @Value("${spring.data.redis.url}")
    private String redisUrl;

    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        URI uri = URI.create(redisUrl);
        boolean useSsl = redisUrl.startsWith("rediss://");

        RedisStandaloneConfiguration standalone = new RedisStandaloneConfiguration();
        standalone.setHostName(uri.getHost());
        standalone.setPort(uri.getPort() > 0 ? uri.getPort() : (useSsl ? 6380 : 6379));

        if (uri.getUserInfo() != null) {
            String[] userInfo = uri.getUserInfo().split(":", 2);
            if (userInfo.length == 2) {
                standalone.setPassword(userInfo[1]);
            }
        }

        LettuceClientConfiguration.LettuceClientConfigurationBuilder builder =
                LettuceClientConfiguration.builder();

        if (useSsl) {
            builder.useSsl()
                   .and()
                   .clientOptions(ClientOptions.builder()
                           .sslOptions(SslOptions.builder().build())
                           .build());
        }

        return new LettuceConnectionFactory(standalone, builder.build());
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.afterPropertiesSet();
        return template;
    }

    @Bean
    public RedisMessageListenerContainer redisMessageListenerContainer(RedisConnectionFactory factory) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(factory);
        return container;
    }
}
