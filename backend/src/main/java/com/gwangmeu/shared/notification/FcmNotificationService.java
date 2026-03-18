package com.gwangmeu.shared.notification;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class FcmNotificationService {

    @Async
    public void sendToToken(String fcmToken, String title, String body, Map<String, String> data) {
        if (!isFirebaseAvailable() || fcmToken == null || fcmToken.isBlank()) {
            return;
        }
        try {
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data != null ? data : Map.of())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.debug("FCM sent to token: {}", response);
        } catch (Exception e) {
            log.warn("FCM send failed for token {}: {}", fcmToken, e.getMessage());
        }
    }

    @Async
    public void sendToTokens(List<String> fcmTokens, String title, String body, Map<String, String> data) {
        for (String token : fcmTokens) {
            sendToToken(token, title, body, data);
        }
    }

    private boolean isFirebaseAvailable() {
        return !FirebaseApp.getApps().isEmpty();
    }
}
