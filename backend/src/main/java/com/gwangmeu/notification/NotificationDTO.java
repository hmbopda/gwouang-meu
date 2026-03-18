package com.gwangmeu.notification;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
public class NotificationDTO {
    private UUID id;
    private String type;
    private String title;
    private String body;
    private Map<String, Object> data;
    private boolean read;
    private Instant createdAt;
}
