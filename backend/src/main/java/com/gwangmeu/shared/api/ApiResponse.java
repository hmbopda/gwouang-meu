package com.gwangmeu.shared.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import org.springframework.data.domain.Page;

import java.time.LocalDateTime;

/**
 * Wrapper uniforme pour toutes les reponses API GWANG MEU.
 * Les erreurs retournent toujours ApiResponse<Void>.
 * Les listes paginées retournent ApiResponse contenant un Page<T>.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
        boolean success,
        T data,
        String message,
        int status,
        LocalDateTime timestamp
) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, "OK", 200, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, data, message, 200, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> created(T data) {
        return new ApiResponse<>(true, data, "Created", 201, LocalDateTime.now());
    }

    public static ApiResponse<Void> noContent() {
        return new ApiResponse<>(true, null, "No Content", 204, LocalDateTime.now());
    }

    public static ApiResponse<Void> error(String message, int status) {
        return new ApiResponse<>(false, null, message, status, LocalDateTime.now());
    }

    public static <T> ApiResponse<PageData<T>> paginated(Page<T> page) {
        PageData<T> pageData = new PageData<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isFirst(),
                page.isLast()
        );
        return new ApiResponse<>(true, pageData, "OK", 200, LocalDateTime.now());
    }

    /**
     * Wrapper pour les reponses paginées.
     */
    public record PageData<T>(
            java.util.List<T> content,
            int page,
            int size,
            long totalElements,
            int totalPages,
            boolean first,
            boolean last
    ) {}
}
