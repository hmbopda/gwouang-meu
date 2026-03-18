package com.gwangmeu.shared.media;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Service d'upload/suppression de medias.
 * - Si R2 est configure : upload vers Cloudflare R2 (S3-compatible).
 * - Sinon : stockage local dans ./uploads/ (fallback dev).
 *
 * Dossiers : avatars/ | covers/ | village-covers/ | posts/ | live-recordings/
 */
@Slf4j
@Service
public class MediaService {

    @Value("${application.r2.access-key-id:}")
    private String accessKeyId;

    @Value("${application.r2.secret-access-key:}")
    private String secretAccessKey;

    @Value("${application.r2.bucket-name:gwangmeu-media}")
    private String bucketName;

    @Value("${application.r2.account-id:}")
    private String accountId;

    @Value("${application.r2.public-url:https://media.gwangmeu.com}")
    private String publicUrl;

    @Value("${application.base-url:http://localhost:8080}")
    private String baseUrl;

    private S3Client s3Client;
    private boolean useLocal;
    private Path localRoot;

    @PostConstruct
    public void init() throws IOException {
        if (accessKeyId.isBlank() || accountId.isBlank()) {
            log.warn("R2 credentials non configures — fallback stockage local ./uploads/");
            useLocal = true;
            localRoot = Path.of("uploads");
            Files.createDirectories(localRoot);
            return;
        }
        useLocal = false;
        String endpoint = "https://" + accountId + ".r2.cloudflarestorage.com";
        this.s3Client = S3Client.builder()
                .endpointOverride(URI.create(endpoint))
                .region(Region.of("auto"))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKeyId, secretAccessKey)
                ))
                .forcePathStyle(true)
                .build();
        log.info("MediaService (R2) initialise sur {}", endpoint);
    }

    public String upload(InputStream inputStream, String contentType, String folder, long size) throws IOException {
        String filename = UUID.randomUUID().toString();
        // Ajouter extension depuis contentType
        String ext = switch (contentType) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/gif" -> ".gif";
            default -> "";
        };
        String key = folder + "/" + filename + ext;

        if (useLocal) {
            Path target = localRoot.resolve(key);
            Files.createDirectories(target.getParent());
            Files.copy(inputStream, target, StandardCopyOption.REPLACE_EXISTING);
            String url = baseUrl + "/uploads/" + key;
            log.info("Media uploaded (local): {}", url);
            return url;
        }

        s3Client.putObject(
                PutObjectRequest.builder().bucket(bucketName).key(key).contentType(contentType).build(),
                RequestBody.fromInputStream(inputStream, size)
        );
        String url = publicUrl + "/" + key;
        log.info("Media uploaded (R2): {}", url);
        return url;
    }

    public void delete(String mediaUrl) {
        if (mediaUrl == null) return;

        if (useLocal) {
            String prefix = baseUrl + "/uploads/";
            if (mediaUrl.startsWith(prefix)) {
                try {
                    Path file = localRoot.resolve(mediaUrl.substring(prefix.length()));
                    Files.deleteIfExists(file);
                    log.info("Media deleted (local): {}", file);
                } catch (IOException e) {
                    log.warn("Echec suppression locale: {}", e.getMessage());
                }
            }
            return;
        }

        if (s3Client == null || !mediaUrl.startsWith(publicUrl)) return;
        String key = mediaUrl.substring(publicUrl.length() + 1);
        s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucketName).key(key).build());
        log.info("Media deleted (R2): {}", key);
    }
}
