-- Fix V22: MIN(uuid) does not exist in PostgreSQL.
-- Use INTERSECT subquery to find the shared parent independently.

CREATE OR REPLACE FUNCTION refresh_siblings()
RETURNS TRIGGER AS $$
DECLARE
    v_child_id UUID;
BEGIN
    v_child_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.child_id ELSE NEW.child_id END;

    -- Supprime les anciens siblings de cet enfant
    DELETE FROM siblings WHERE person_a_id = v_child_id OR person_b_id = v_child_id;

    -- Recalcule : tous les enfants qui partagent au moins un parent avec v_child_id
    INSERT INTO siblings(person_a_id, person_b_id, sibling_type, shared_parents)
    SELECT
        LEAST(v_child_id, pc2.child_id),
        GREATEST(v_child_id, pc2.child_id),
        CASE COUNT(DISTINCT pc1.parent_id)
            WHEN 2 THEN 'FULL'::sibling_type_enum
            ELSE (
                SELECT CASE
                    WHEN pr.parent_role = 'FATHER' THEN 'HALF_PATERNAL'
                    ELSE 'HALF_MATERNAL'
                END
                FROM parent_child pr
                WHERE pr.child_id = v_child_id
                  AND pr.parent_id IN (
                      SELECT sp.parent_id FROM parent_child sp
                      WHERE sp.child_id = v_child_id
                      INTERSECT
                      SELECT sp.parent_id FROM parent_child sp
                      WHERE sp.child_id = pc2.child_id
                  )
                LIMIT 1
            )::sibling_type_enum
        END,
        COUNT(DISTINCT pc1.parent_id)::SMALLINT
    FROM parent_child pc1
    JOIN parent_child pc2 ON pc1.parent_id = pc2.parent_id
    WHERE pc1.child_id = v_child_id
      AND pc2.child_id != v_child_id
    GROUP BY pc2.child_id
    ON CONFLICT (person_a_id, person_b_id) DO UPDATE
      SET sibling_type = EXCLUDED.sibling_type,
          shared_parents = EXCLUDED.shared_parents;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
