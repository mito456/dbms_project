-- ============================================================================
-- Research Collaboration & Publication Intelligence System
-- File: 04_advanced_sql.sql
-- Description: Views, Triggers, Functions, Stored Procedures, and Indexes.
-- ============================================================================

-- ============================================================================
-- SECTION 1: VIEWS
-- Views provide abstract, secure, and simplified query interfaces.
-- NOTE: Standard (dynamic) views are used instead of MATERIALIZED views here
-- because research databases require real-time accuracy without the periodic
-- overhead and stale data issues of REFRESH MATERIALIZED VIEW.
-- ============================================================================

-- View 1: Publication Details with Aggregated Author Names and Topics
-- Consolidates publication metadata, formatted author citations, and tagged topics.
CREATE OR REPLACE VIEW v_publication_details AS
SELECT 
    p.publication_id,
    p.title,
    p.publication_date,
    p.doi,
    p.url,
    STRING_AGG(DISTINCT r.name, ', ' ORDER BY r.name) AS authors,
    COUNT(DISTINCT a.researcher_id) AS author_count,
    STRING_AGG(DISTINCT t.name, '; ' ORDER BY t.name) AS topics
FROM publication p
LEFT JOIN authorship a ON p.publication_id = a.publication_id
LEFT JOIN researcher r ON a.researcher_id = r.researcher_id
LEFT JOIN publication_topic pt ON p.publication_id = pt.publication_id
LEFT JOIN research_topic t ON pt.topic_id = t.topic_id
GROUP BY p.publication_id, p.title, p.publication_date, p.doi, p.url;

COMMENT ON VIEW v_publication_details IS 'Consolidated view of publications with concatenated authors and topics';

-- View 2: Researcher Publication Counts and Career Metrics
-- Summarizes researcher productivity and first-author counts.
CREATE OR REPLACE VIEW v_researcher_publication_counts AS
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    r.email,
    COUNT(a.publication_id) AS total_publications,
    COUNT(CASE WHEN a.author_order = 1 THEN 1 END) AS lead_author_publications
FROM researcher r
LEFT JOIN authorship a ON r.researcher_id = a.researcher_id
GROUP BY r.researcher_id, r.name, r.institution, r.email;

COMMENT ON VIEW v_researcher_publication_counts IS 'Summary of researcher publication productivity and lead-author counts';

-- View 3: Upcoming Conferences with Deadlines & Time Remaining
-- Automatically filters for active, non-expired conferences.
CREATE OR REPLACE VIEW v_upcoming_conferences AS
SELECT 
    c.conference_id,
    c.name AS conference_name,
    c.location,
    c.submission_deadline,
    c.start_date,
    c.end_date,
    c.status,
    (c.submission_deadline - CURRENT_DATE) AS days_until_deadline,
    STRING_AGG(DISTINCT t.name, ', ' ORDER BY t.name) AS topic_tracks
FROM conference c
LEFT JOIN conference_topic ct ON c.conference_id = ct.conference_id
LEFT JOIN research_topic t ON ct.topic_id = t.topic_id
WHERE c.status = 'upcoming' 
  AND c.submission_deadline >= CURRENT_DATE
GROUP BY c.conference_id, c.name, c.location, c.submission_deadline, c.start_date, c.end_date, c.status;

COMMENT ON VIEW v_upcoming_conferences IS 'Active upcoming conferences with submission deadline countdowns';

-- View 4: Bidirectional Collaborations
-- Flattens the canonical undirected pair (id1 < id2) so an application can
-- query for all collaborators of researcher X without complex OR clauses.
CREATE OR REPLACE VIEW v_collaborations_bidirectional AS
SELECT 
    c.collaboration_id,
    c.researcher_id_1 AS researcher_id,
    c.researcher_id_2 AS collaborator_id,
    r2.name AS collaborator_name,
    r2.institution AS collaborator_institution,
    c.similarity_score,
    c.created_at
FROM collaboration c
JOIN researcher r2 ON c.researcher_id_2 = r2.researcher_id
UNION ALL
SELECT 
    c.collaboration_id,
    c.researcher_id_2 AS researcher_id,
    c.researcher_id_1 AS collaborator_id,
    r1.name AS collaborator_name,
    r1.institution AS collaborator_institution,
    c.similarity_score,
    c.created_at
FROM collaboration c
JOIN researcher r1 ON c.researcher_id_1 = r1.researcher_id;

COMMENT ON VIEW v_collaborations_bidirectional IS 'Bidirectional symmetric view over canonical undirected collaborations';

-- ============================================================================
-- SECTION 2: TRIGGERS
-- Triggers automate database actions in response to DML operations.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: Automatic Timestamp Maintenance (updated_at)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Apply to publication
DROP TRIGGER IF EXISTS trg_publication_updated_at ON publication;
CREATE TRIGGER trg_publication_updated_at
    BEFORE UPDATE ON publication
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- Apply to conference
DROP TRIGGER IF EXISTS trg_conference_updated_at ON conference;
CREATE TRIGGER trg_conference_updated_at
    BEFORE UPDATE ON conference
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- ----------------------------------------------------------------------------
-- Trigger 2: Administrative Audit Trail Trigger
-- Records conference updates into admin_audit_log.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit_conference_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only write audit log if meaningful columns changed
    IF (OLD.status <> NEW.status OR OLD.submission_deadline <> NEW.submission_deadline) THEN
        INSERT INTO admin_audit_log (
            admin_id, 
            target_table, 
            target_id, 
            action_type, 
            old_values, 
            new_values, 
            performed_at
        )
        VALUES (
            NULL, -- Can be enriched via application context / session variable
            'conference',
            NEW.conference_id,
            'UPDATE',
            jsonb_build_object('status', OLD.status, 'submission_deadline', OLD.submission_deadline),
            jsonb_build_object('status', NEW.status, 'submission_deadline', NEW.submission_deadline),
            CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_conference_changes ON conference;
CREATE TRIGGER trg_audit_conference_changes
    AFTER UPDATE ON conference
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_conference_changes();

-- ============================================================================
-- SECTION 3: STORED FUNCTIONS AND PROCEDURES
-- In PostgreSQL:
-- - FUNCTION: Called with SELECT, returns a value/table, executes in caller tx.
-- - PROCEDURE: Called with CALL, manages transactions (can COMMIT/ROLLBACK).
-- ============================================================================

-- Function 1: Get Publication Count for a Researcher
CREATE OR REPLACE FUNCTION fn_get_researcher_pub_count(p_researcher_id BIGINT)
RETURNS INT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_count INT := 0;
    v_exists BOOLEAN;
BEGIN
    -- Verify researcher existence
    SELECT EXISTS(SELECT 1 FROM researcher WHERE researcher_id = p_researcher_id) INTO v_exists;
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Researcher with ID % does not exist.', p_researcher_id;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM authorship
    WHERE researcher_id = p_researcher_id;

    RETURN v_count;
END;
$$;

COMMENT ON FUNCTION fn_get_researcher_pub_count IS 'Returns total number of publications for a given researcher ID';

-- Function 2: Calculate Jaccard Similarity on Shared Research Topics
-- Computes |A ∩ B| / |A ∪ B| between two researchers based on declared topics.
CREATE OR REPLACE FUNCTION fn_calculate_topic_similarity(p_res1 BIGINT, p_res2 BIGINT)
RETURNS NUMERIC(5, 4)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_intersection_count INT;
    v_union_count INT;
    v_similarity NUMERIC(5, 4) := 0.0000;
BEGIN
    IF p_res1 = p_res2 THEN
        RETURN 1.0000;
    END IF;

    -- Count shared topics (intersection)
    SELECT COUNT(*) INTO v_intersection_count
    FROM researcher_topic t1
    JOIN researcher_topic t2 ON t1.topic_id = t2.topic_id
    WHERE t1.researcher_id = p_res1 AND t2.researcher_id = p_res2;

    -- Count distinct total topics (union)
    SELECT COUNT(DISTINCT topic_id) INTO v_union_count
    FROM researcher_topic
    WHERE researcher_id IN (p_res1, p_res2);

    IF v_union_count = 0 THEN
        RETURN 0.0000;
    END IF;

    v_similarity := ROUND((v_intersection_count::NUMERIC / v_union_count::NUMERIC), 4);
    RETURN v_similarity;
END;
$$;

COMMENT ON FUNCTION fn_calculate_topic_similarity IS 'Computes Jaccard topic similarity coefficient between two researchers';

-- Stored Procedure 1: Update Conference Status with Audit Logging
CREATE OR REPLACE PROCEDURE sp_update_conference_status(
    p_conference_id BIGINT,
    p_new_status VARCHAR,
    p_admin_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    -- Validate status value
    IF p_new_status NOT IN ('upcoming', 'ongoing', 'completed', 'postponed', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid conference status: %. Must be upcoming, ongoing, completed, postponed, or cancelled.', p_new_status;
    END IF;

    -- Validate admin existence
    IF NOT EXISTS (SELECT 1 FROM admin WHERE admin_id = p_admin_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Active Admin ID % not found.', p_admin_id;
    END IF;

    -- Retrieve existing status
    SELECT status INTO v_old_status
    FROM conference
    WHERE conference_id = p_conference_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Conference ID % does not exist.', p_conference_id;
    END IF;

    -- Perform update
    UPDATE conference
    SET status = p_new_status
    WHERE conference_id = p_conference_id;

    -- Explicitly log admin action
    INSERT INTO admin_audit_log (admin_id, target_table, target_id, action_type, old_values, new_values)
    VALUES (
        p_admin_id,
        'conference',
        p_conference_id,
        'UPDATE',
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status)
    );

    RAISE NOTICE 'Conference % status updated from % to % by Admin %', p_conference_id, v_old_status, p_new_status, p_admin_id;
END;
$$;

COMMENT ON PROCEDURE sp_update_conference_status IS 'Updates conference status and records administrative audit trail';

-- ============================================================================
-- SECTION 4: INDEXES AND QUERY OPTIMIZATION
-- Indexes accelerate SELECT query filters and JOINs at the cost of slight
-- write overhead during INSERT, UPDATE, and DELETE.
-- ============================================================================

-- 1. Index on Publication Date (for timeline filtering and recent paper lookups)
CREATE INDEX idx_publication_date ON publication (publication_date DESC);

-- 1b. Vector Index on Publication Embeddings (HNSW index using cosine distance)
CREATE INDEX idx_publication_embedding_hnsw ON publication USING hnsw (embedding vector_cosine_ops);

-- 2. Index on Conference Submission Deadline (for upcoming deadline queries)
CREATE INDEX idx_conference_submission_deadline ON conference (submission_deadline ASC);

-- 3. Indexes on Many-to-Many Foreign Keys
-- NOTE: In composite primary keys like authorship(researcher_id, publication_id),
-- the leading column (researcher_id) is already indexed. However, reverse lookups
-- on the second column (publication_id) require a dedicated index for fast joins.
CREATE INDEX idx_authorship_publication_id ON authorship (publication_id);
CREATE INDEX idx_researcher_project_project_id ON researcher_project (project_id);
CREATE INDEX idx_researcher_topic_topic_id ON researcher_topic (topic_id);
CREATE INDEX idx_publication_topic_topic_id ON publication_topic (topic_id);
CREATE INDEX idx_conference_topic_topic_id ON conference_topic (topic_id);

-- 4. Reverse Index on Collaboration
-- collaboration PK is collaboration_id; unique constraint indexes (researcher_id_1, researcher_id_2).
-- To quickly search for collaborations where a user is researcher_id_2:
CREATE INDEX idx_collaboration_researcher_2 ON collaboration (researcher_id_2);

-- 5. Partial Index: Active Projects
-- Small, high-speed index focusing only on active projects.
CREATE INDEX idx_project_active ON project (project_id) WHERE status = 'active';

-- ============================================================================
-- QUERY OPTIMIZATION DEMONSTRATION: EXPLAIN & EXPLAIN ANALYZE
-- ============================================================================
-- EXPLAIN: Shows the PostgreSQL cost-based query plan without executing the query.
-- EXPLAIN ANALYZE: Actually executes the query and reports real runtime execution times.

-- Example: Check query plan using the new publication_date index
EXPLAIN ANALYZE
SELECT publication_id, title, publication_date
FROM publication
WHERE publication_date >= '2024-01-01'
ORDER BY publication_date DESC;
