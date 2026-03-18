package com.gwangmeu.shared.ai;

/**
 * Modeles Claude disponibles pour GWANG MEU.
 * Ref ARCHITECTURE.md — section Claude AI.
 *
 * SONNET : taches courantes (guide, quiz, moderation, resume)
 * OPUS   : taches complexes (enrichissement culturel profond, arbres complexes)
 */
public enum ClaudeModel {

    SONNET("claude-sonnet-4-6"),
    OPUS("claude-opus-4-6");

    private final String modelId;

    ClaudeModel(String modelId) {
        this.modelId = modelId;
    }

    public String getModelId() {
        return modelId;
    }
}
