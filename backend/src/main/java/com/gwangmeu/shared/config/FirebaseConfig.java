package com.gwangmeu.shared.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Initialisation du SDK Firebase Admin (FCM Push Notifications).
 */
@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${application.firebase.service-account-json:{}}")
    private String serviceAccountJson;

    @PostConstruct
    public void initialize() {
        if (serviceAccountJson == null || serviceAccountJson.isBlank() || serviceAccountJson.equals("{}")) {
            log.warn("Firebase service account JSON not configured — FCM disabled");
            return;
        }
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                GoogleCredentials credentials = GoogleCredentials.fromStream(
                        new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8))
                );
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(credentials)
                        .build();
                FirebaseApp.initializeApp(options);
                log.info("Firebase initialized successfully");
            }
        } catch (IOException e) {
            log.error("Firebase initialization failed: {}", e.getMessage());
        }
    }
}
