package com.gwangmeu.notification;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final UserIdResolver userIdResolver;

    @GetMapping
    @Operation(summary = "Get all notifications for the current user")
    public ResponseEntity<ApiResponse<List<NotificationDTO>>> getNotifications(@CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        List<NotificationDTO> dtos = notificationService.getByUser(userId).stream()
                .map(this::toDTO)
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get unread notification count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(@CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        long count = notificationService.countUnread(userId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("count", count)));
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark a notification as read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable UUID id, @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        notificationService.markAsRead(id, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    @PatchMapping("/read-all")
    @Operation(summary = "Mark all notifications as read")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(@CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    private NotificationDTO toDTO(Notification n) {
        return NotificationDTO.builder()
                .id(n.getId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .data(n.getData())
                .read(n.isRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
