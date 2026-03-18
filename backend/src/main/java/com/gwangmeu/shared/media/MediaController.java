package com.gwangmeu.shared.media;

import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/media")
@RequiredArgsConstructor
@Tag(name = "Media", description = "Upload de fichiers medias vers Cloudflare R2")
public class MediaController {

    private final MediaService mediaService;

    private static final long MAX_SIZE = 5 * 1024 * 1024; // 5 MB
    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp", "image/gif"
    );
    private static final Set<String> ALLOWED_FOLDERS = Set.of(
            "avatars", "covers", "posts", "village-covers"
    );

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload un fichier media",
            description = "Upload une image (max 5MB, jpeg/png/webp/gif) vers R2. "
                    + "Retourne l'URL publique. Folders: avatars, covers, posts, village-covers.")
    @SuppressWarnings("unchecked")
    public ResponseEntity<ApiResponse<?>> upload(
            @CurrentUser Jwt jwt,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folder", defaultValue = "avatars") String folder
    ) throws IOException {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Fichier vide", 400));
        }
        if (file.getSize() > MAX_SIZE) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Fichier trop volumineux (max 5 MB)", 400));
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType)) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Type non supporte. Acceptes: jpeg, png, webp, gif", 400));
        }
        if (!ALLOWED_FOLDERS.contains(folder)) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Dossier invalide: " + folder, 400));
        }

        String url = mediaService.upload(file.getInputStream(), contentType, folder, file.getSize());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("url", url), "Upload reussi"));
    }
}
