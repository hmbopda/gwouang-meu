package com.gwangmeu.chat.domain;

import com.gwangmeu.shared.audit.AuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "chat_messages",
        indexes = {
                @Index(name = "idx_chat_msg_group_date", columnList = "group_id, created_at DESC"),
                @Index(name = "idx_chat_msg_sender", columnList = "sender_id")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage extends AuditEntity {

    @Column(name = "group_id", nullable = false)
    private UUID groupId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private MessageType type = MessageType.TEXT;

    public enum MessageType {
        TEXT,
        IMAGE,
        SYSTEM
    }
}
