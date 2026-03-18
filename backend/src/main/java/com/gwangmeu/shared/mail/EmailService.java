package com.gwangmeu.shared.mail;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${application.mail-from}")
    private String fromAddress;

    @Value("${application.base-url}")
    private String baseUrl;

    /**
     * Envoie un email d'invitation. Retourne true si l'envoi reussit, false sinon
     * (permet le fallback vers SMS).
     */
    public boolean sendInvitationEmail(String to, String inviterName, String personFirstName, String token) {
        String inviteLink = baseUrl + "/invite?token=" + token;
        String subject = inviterName + " vous invite a rejoindre votre arbre genealogique sur Gwang Meu";
        String html = buildInvitationHtml(inviterName, personFirstName, inviteLink);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
            log.info("Email d'invitation envoye a {}", to);
            return true;
        } catch (MessagingException | RuntimeException e) {
            log.error("Echec envoi email a {} : {}", to, e.getMessage());
            return false;
        }
    }

    /**
     * Envoie un email de notification de dissolution (divorce ou deces).
     */
    public boolean sendDissolutionEmail(String to, String requesterName,
                                        String recipientFirstName, String type, String unionId) {
        String subject;
        String contextText;
        if ("DIVORCE".equals(type)) {
            subject = "Demande de divorce sur Gwang Meu";
            contextText = "<strong>" + requesterName + "</strong> a initie une demande de divorce vous concernant.";
        } else if ("DEATH".equals(type)) {
            subject = "Declaration de deces vous concernant sur Gwang Meu";
            contextText = "<strong>" + requesterName + "</strong> a declare votre deces. " +
                    "Si vous etes bien vivant(e), veuillez contester cette declaration.";
        } else {
            // DEATH_FAMILY — notification famille
            subject = "Declaration de deces d'un membre de votre famille";
            contextText = "<strong>" + requesterName + "</strong> a declare le deces d'un membre de votre famille. " +
                    "Connectez-vous a Gwang Meu pour plus de details.";
        }

        String html = buildDissolutionHtml(recipientFirstName, contextText);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
            log.info("Email dissolution ({}) envoye a {}", type, to);
            return true;
        } catch (MessagingException | RuntimeException e) {
            log.error("Echec envoi email dissolution a {} : {}", to, e.getMessage());
            return false;
        }
    }

    /**
     * Envoie un email de notification de creation d'union.
     */
    public boolean sendUnionEmail(String to, String recipientFirstName, String spouseName) {
        String subject = "Nouvelle union enregistree sur Gwang Meu";
        String contextText = "Une union entre vous et <strong>" + spouseName
                + "</strong> a ete enregistree sur Gwang Meu. "
                + "Connectez-vous a votre compte pour voir les details.";

        String html = buildDissolutionHtml(recipientFirstName, contextText);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
            log.info("Email union envoye a {}", to);
            return true;
        } catch (MessagingException | RuntimeException e) {
            log.error("Echec envoi email union a {} : {}", to, e.getMessage());
            return false;
        }
    }

    /**
     * Envoie un email de demande d'association d'un enfant a un co-parent.
     * Redirige vers l'app (pas de lien de validation directe par email).
     */
    public boolean sendChildAssociationEmail(String to, String recipientFirstName,
                                              String requesterName, String childName) {
        String subject = "Demande d'association d'un enfant – " + childName;
        String notificationsLink = baseUrl + "/notifications";
        String contextText = "<strong>" + requesterName + "</strong> souhaite associer l'enfant <strong>"
                + childName + "</strong> a votre arbre genealogique. "
                + "Confirmez-vous cette filiation ?";

        String html = buildChildAssociationHtml(recipientFirstName, contextText, notificationsLink);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
            log.info("Email child association envoye a {}", to);
            return true;
        } catch (MessagingException | RuntimeException e) {
            log.error("Echec envoi email child association a {} : {}", to, e.getMessage());
            return false;
        }
    }

    private String buildChildAssociationHtml(String recipientFirstName, String contextText, String ctaLink) {
        return """
            <!DOCTYPE html>
            <html lang="fr">
            <head><meta charset="UTF-8"></head>
            <body style="margin:0;padding:0;background-color:#f4f4f4;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
              <table width="100%%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f4;padding:40px 0;">
                <tr>
                  <td align="center">
                    <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">
                      <tr>
                        <td style="background-color:#D4A017;padding:32px 40px;text-align:center;">
                          <h1 style="margin:0;color:#1a1a1a;font-size:26px;font-weight:700;">Gwang Meu</h1>
                          <p style="margin:6px 0 0;color:#1a1a1a;font-size:13px;opacity:0.8;">Preservation culturelle &amp; genealogie africaine</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:40px;">
                          <h2 style="margin:0 0 8px;color:#333;font-size:20px;">Bonjour %s,</h2>
                          <p style="margin:0 0 20px;color:#555;font-size:15px;line-height:1.6;">
                            %s
                          </p>
                          <p style="margin:0 0 28px;color:#555;font-size:15px;line-height:1.6;">
                            Connectez-vous a Gwang Meu pour valider ou refuser cette demande.
                          </p>
                          <table width="100%%" cellpadding="0" cellspacing="0">
                            <tr>
                              <td align="center">
                                <a href="%s"
                                   style="display:inline-block;background-color:#D4A017;color:#1a1a1a;text-decoration:none;
                                          padding:14px 40px;border-radius:8px;font-size:16px;font-weight:600;
                                          box-shadow:0 2px 8px rgba(212,160,23,0.3);">
                                  Voir la demande
                                </a>
                              </td>
                            </tr>
                          </table>
                          <hr style="margin:28px 0;border:none;border-top:1px solid #eee;"/>
                          <p style="margin:0;color:#999;font-size:12px;">
                            Si vous ne comprenez pas cet email, connectez-vous a Gwang Meu ou contactez le support.
                          </p>
                        </td>
                      </tr>
                      <tr>
                        <td style="background-color:#fafafa;padding:20px 40px;text-align:center;border-top:1px solid #eee;">
                          <p style="margin:0;color:#aaa;font-size:11px;">
                            &copy; Gwang Meu — Ensemble, preservons nos racines.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """.formatted(recipientFirstName, contextText, ctaLink);
    }

    private String buildDissolutionHtml(String recipientFirstName, String contextText) {
        return """
            <!DOCTYPE html>
            <html lang="fr">
            <head><meta charset="UTF-8"></head>
            <body style="margin:0;padding:0;background-color:#f4f4f4;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
              <table width="100%%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f4;padding:40px 0;">
                <tr>
                  <td align="center">
                    <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">
                      <tr>
                        <td style="background-color:#D4A017;padding:32px 40px;text-align:center;">
                          <h1 style="margin:0;color:#1a1a1a;font-size:26px;font-weight:700;">Gwang Meu</h1>
                          <p style="margin:6px 0 0;color:#1a1a1a;font-size:13px;opacity:0.8;">Preservation culturelle &amp; genealogie africaine</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:40px;">
                          <h2 style="margin:0 0 8px;color:#333;font-size:20px;">Bonjour %s,</h2>
                          <p style="margin:0 0 20px;color:#555;font-size:15px;line-height:1.6;">
                            %s
                          </p>
                          <p style="margin:0 0 20px;color:#555;font-size:15px;line-height:1.6;">
                            Connectez-vous a votre compte Gwang Meu pour voir les details et reagir.
                          </p>
                          <hr style="margin:28px 0;border:none;border-top:1px solid #eee;"/>
                          <p style="margin:0;color:#999;font-size:12px;">
                            Si vous ne comprenez pas cet email, connectez-vous a Gwang Meu ou contactez le support.
                          </p>
                        </td>
                      </tr>
                      <tr>
                        <td style="background-color:#fafafa;padding:20px 40px;text-align:center;border-top:1px solid #eee;">
                          <p style="margin:0;color:#aaa;font-size:11px;">
                            &copy; Gwang Meu — Ensemble, preservons nos racines.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """.formatted(recipientFirstName, contextText);
    }

    private String buildInvitationHtml(String inviterName, String personFirstName, String inviteLink) {
        return """
            <!DOCTYPE html>
            <html lang="fr">
            <head><meta charset="UTF-8"></head>
            <body style="margin:0;padding:0;background-color:#f4f4f4;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
              <table width="100%%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f4;padding:40px 0;">
                <tr>
                  <td align="center">
                    <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">
                      <!-- Header -->
                      <tr>
                        <td style="background-color:#D4A017;padding:32px 40px;text-align:center;">
                          <h1 style="margin:0;color:#1a1a1a;font-size:26px;font-weight:700;">Gwang Meu</h1>
                          <p style="margin:6px 0 0;color:#1a1a1a;font-size:13px;opacity:0.8;">Preservation culturelle &amp; genealogie africaine</p>
                        </td>
                      </tr>
                      <!-- Body -->
                      <tr>
                        <td style="padding:40px;">
                          <h2 style="margin:0 0 8px;color:#333;font-size:20px;">Bonjour %s,</h2>
                          <p style="margin:0 0 20px;color:#555;font-size:15px;line-height:1.6;">
                            <strong>%s</strong> vous a ajoute a son arbre genealogique sur Gwang Meu
                            et souhaite que vous confirmiez votre identite.
                          </p>
                          <p style="margin:0 0 28px;color:#555;font-size:15px;line-height:1.6;">
                            En cliquant sur le bouton ci-dessous, vous pourrez verifier vos informations,
                            les corriger si necessaire, et creer votre compte pour rejoindre votre famille.
                          </p>
                          <!-- CTA Button -->
                          <table width="100%%" cellpadding="0" cellspacing="0">
                            <tr>
                              <td align="center">
                                <a href="%s"
                                   style="display:inline-block;background-color:#D4A017;color:#1a1a1a;text-decoration:none;
                                          padding:14px 40px;border-radius:8px;font-size:16px;font-weight:600;
                                          box-shadow:0 2px 8px rgba(212,160,23,0.3);">
                                  Confirmer mon identite
                                </a>
                              </td>
                            </tr>
                          </table>
                          <p style="margin:28px 0 0;color:#888;font-size:12px;line-height:1.5;">
                            Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur&nbsp;:<br/>
                            <a href="%s" style="color:#D4A017;word-break:break-all;">%s</a>
                          </p>
                          <hr style="margin:28px 0;border:none;border-top:1px solid #eee;"/>
                          <p style="margin:0;color:#999;font-size:12px;">
                            Ce lien est valable 30 jours. Si vous ne connaissez pas <strong>%s</strong>,
                            vous pouvez ignorer cet email en toute securite.
                          </p>
                        </td>
                      </tr>
                      <!-- Footer -->
                      <tr>
                        <td style="background-color:#fafafa;padding:20px 40px;text-align:center;border-top:1px solid #eee;">
                          <p style="margin:0;color:#aaa;font-size:11px;">
                            &copy; Gwang Meu — Ensemble, preservons nos racines.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
            """.formatted(personFirstName, inviterName, inviteLink, inviteLink, inviteLink, inviterName);
    }
}
