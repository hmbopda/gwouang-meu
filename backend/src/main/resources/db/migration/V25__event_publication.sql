-- Spring Modulith JPA event publication table
-- Required by spring-modulith-starter-jpa for transactional event persistence
CREATE TABLE IF NOT EXISTS event_publication (
    id               UUID                     NOT NULL PRIMARY KEY,
    completion_date  TIMESTAMP WITH TIME ZONE,
    event_type       VARCHAR(512)             NOT NULL,
    listener_id      VARCHAR(512)             NOT NULL,
    publication_date TIMESTAMP WITH TIME ZONE NOT NULL,
    serialized_event TEXT                     NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_event_publication_completion_date
    ON event_publication (completion_date);
