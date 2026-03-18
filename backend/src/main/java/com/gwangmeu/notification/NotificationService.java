package com.gwangmeu.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    /**
     * Crée une notification in-app pour un utilisateur.
     */
    public Notification create(UUID userId, String type, String title, String body, Map<String, Object> data) {
        Notification notif = Notification.builder()
                .userId(userId)
                .type(type)
                .title(title)
                .body(body)
                .data(data)
                .build();
        Notification saved = notificationRepository.save(notif);
        log.info("Notification creee: user={}, type={}, title={}", userId, type, title);
        return saved;
    }

    public List<Notification> getByUser(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public long countUnread(UUID userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    @Transactional
    public void markAsRead(UUID notifId, UUID userId) {
        Notification notif = notificationRepository.findById(notifId)
                .orElseThrow(() -> new IllegalArgumentException("Notification non trouvee"));
        if (!notif.getUserId().equals(userId)) {
            throw new IllegalStateException("Cette notification ne vous appartient pas");
        }
        notif.setRead(true);
        notificationRepository.save(notif);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndReadFalseOrderByCreatedAtDesc(userId);
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
    }
}
