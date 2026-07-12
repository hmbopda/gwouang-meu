package com.gwangmeu.shared.mail;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

/**
 * Transport SMTP (via {@link JavaMailSender}). Provider par defaut.
 * Actif tant que {@code application.mail.provider} vaut {@code smtp} ou est absent.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "application.mail.provider", havingValue = "smtp", matchIfMissing = true)
class SmtpEmailSender implements EmailSender {

    private final JavaMailSender mailSender;

    @Override
    public boolean send(String from, String to, String subject, String html) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
            return true;
        } catch (MessagingException | RuntimeException e) {
            log.error("SMTP: echec envoi a {} : {}", to, e.getMessage());
            return false;
        }
    }

    @Override
    public String providerName() {
        return "smtp";
    }
}
