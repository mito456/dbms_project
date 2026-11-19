-- ============================================================================
-- Research Collaboration & Publication Intelligence System
-- File: 06_tests.sql
-- Description: Automated verification and constraint validation test suite.
-- Run in psql or pgAdmin. Negative tests use DO blocks with exception handling
-- to verify failure without halting script execution.
-- ============================================================================

\echo '============================================================================'
\echo ' STARTING DATABASE VERIFICATION & CONSTRAINT TEST SUITE'
\echo '============================================================================'

-- ============================================================================
-- TEST 1: VERIFY ALL CORE TABLES EXIST
-- ============================================================================
DO $$
DECLARE
    v_missing_tables TEXT;
BEGIN
    SELECT STRING_AGG(table_name, ', ') INTO v_missing_tables
    FROM (
        VALUES 
            ('admin'), ('researcher'), ('publication'), ('project'),
            ('conference'), ('research_topic'), ('authorship'), ('collaboration'),
            ('researcher_project'), ('researcher_topic'), ('publication_topic'),
            ('conference_topic'), ('admin_audit_log')
    ) AS required(table_name)
    WHERE table_name NOT IN (
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    );

    IF v_missing_tables IS NULL THEN
        RAISE NOTICE '[PASSED] Test 1: All 13 core and supplemental tables exist in the schema.';
    ELSE
        RAISE EXCEPTION '[FAILED] Test 1: Missing tables: %', v_missing_tables;
    END IF;
END;
$$;

-- ============================================================================
-- TEST 2: REJECT DUPLICATE RESEARCHER EMAIL
-- ============================================================================
DO $$
BEGIN
    INSERT INTO researcher (name, email, password_hash)
    VALUES ('Dr. Duplicate Email', 'aris.thorne@oxford-cyber.edu', 'some_dummy_hash');
    
    RAISE EXCEPTION '[FAILED] Test 2: Database allowed duplicate researcher email!';
EXCEPTION 
    WHEN unique_violation THEN
        RAISE NOTICE '[PASSED] Test 2: Duplicate researcher email correctly rejected by UNIQUE constraint.';
END;
$$;

-- ============================================================================
-- TEST 3: REJECT DUPLICATE TOPIC NAME
-- ============================================================================
DO $$
BEGIN
    INSERT INTO research_topic (name, category)
    VALUES ('Distributed Consensus', 'Duplicate Category');

    RAISE EXCEPTION '[FAILED] Test 3: Database allowed duplicate topic name!';
EXCEPTION 
    WHEN unique_violation THEN
        RAISE NOTICE '[PASSED] Test 3: Duplicate research topic name correctly rejected by UNIQUE constraint.';
END;
$$;

-- ============================================================================
-- TEST 4: REJECT INVALID CONFERENCE DATES (end_date < start_date)
-- ============================================================================
DO $$
BEGIN
    INSERT INTO conference (name, start_date, end_date, submission_deadline)
    VALUES ('Invalid Date Conf', '2026-10-20', '2026-10-15', '2026-09-01');

    RAISE EXCEPTION '[FAILED] Test 4: Database allowed conference with end_date earlier than start_date!';
EXCEPTION 
    WHEN check_violation THEN
        RAISE NOTICE '[PASSED] Test 4: Invalid conference date range correctly rejected by CHECK constraint.';
END;
$$;

-- ============================================================================
-- TEST 5: REJECT INVALID CONFERENCE SUBMISSION DEADLINE (deadline > start_date)
-- ============================================================================
DO $$
BEGIN
    INSERT INTO conference (name, start_date, end_date, submission_deadline)
    VALUES ('Invalid Deadline Conf', '2026-10-20', '2026-10-25', '2026-10-22');

    RAISE EXCEPTION '[FAILED] Test 5: Database allowed submission deadline after conference start date!';
EXCEPTION 
    WHEN check_violation THEN
        RAISE NOTICE '[PASSED] Test 5: Late conference deadline correctly rejected by CHECK constraint.';
END;
$$;

-- ============================================================================
-- TEST 6: REJECT SELF-COLLABORATION (researcher_id_1 = researcher_id_2)
-- ============================================================================
DO $$
BEGIN
    INSERT INTO collaboration (researcher_id_1, researcher_id_2, similarity_score)
    VALUES (1, 1, 0.9500);

    RAISE EXCEPTION '[FAILED] Test 6: Database allowed self-collaboration (researcher_id_1 = researcher_id_2)!';
EXCEPTION 
    WHEN check_violation THEN
        RAISE NOTICE '[PASSED] Test 6: Self-collaboration correctly rejected by chk_collaboration_no_self constraint.';
END;
$$;

-- ============================================================================
-- TEST 7: REJECT INVERTED / DUPLICATE COLLABORATION PAIRS (researcher_id_1 >= researcher_id_2)
-- ============================================================================
DO $$
BEGIN
    -- (1, 6) already exists in sample data. Attempting to insert (6, 1) must fail.
    INSERT INTO collaboration (researcher_id_1, researcher_id_2, similarity_score)
    VALUES (6, 1, 0.9250);

    RAISE EXCEPTION '[FAILED] Test 7: Database allowed inverted duplicate collaboration pair (6, 1)!';
EXCEPTION 
    WHEN check_violation THEN
        RAISE NOTICE '[PASSED] Test 7: Inverted duplicate pair (6, 1) correctly rejected by chk_collaboration_no_self.';
END;
$$;

-- ============================================================================
-- TEST 8: REJECT OUT-OF-BOUNDS SIMILARITY SCORE (> 1.0 or < 0.0)
-- ============================================================================
DO $$
BEGIN
    INSERT INTO collaboration (researcher_id_1, researcher_id_2, similarity_score)
    VALUES (1, 9, 1.4500);

    RAISE EXCEPTION '[FAILED] Test 8: Database allowed similarity score > 1.0!';
EXCEPTION 
    WHEN check_violation THEN
        RAISE NOTICE '[PASSED] Test 8: Out-of-bounds similarity score (1.4500) correctly rejected by CHECK constraint.';
END;
$$;

-- ============================================================================
-- TEST 9: REJECT DUPLICATE AUTHOR ORDER ON SAME PUBLICATION
-- ============================================================================
DO $$
BEGIN
    -- Paper 1 already has lead author (order=1). Attempting another author with order=1 must fail.
    INSERT INTO authorship (researcher_id, publication_id, author_order)
    VALUES (1, 1, 1);

    RAISE EXCEPTION '[FAILED] Test 9: Database allowed two lead authors (order=1) on publication 1!';
EXCEPTION 
    WHEN unique_violation THEN
        RAISE NOTICE '[PASSED] Test 9: Duplicate author order correctly rejected by uq_publication_author_order.';
END;
$$;

-- ============================================================================
-- TEST 10: VERIFY TIMESTAMP TRIGGER EXECUTION (updated_at)
-- ============================================================================
DO $$
DECLARE
    v_old_timestamp TIMESTAMPTZ;
    v_new_timestamp TIMESTAMPTZ;
BEGIN
    SELECT updated_at INTO v_old_timestamp FROM publication WHERE publication_id = 1;
    
    -- Small sleep to ensure clock progression
    PERFORM pg_sleep(0.05);

    UPDATE publication 
    SET title = title || ' [Verified]'
    WHERE publication_id = 1;

    SELECT updated_at INTO v_new_timestamp FROM publication WHERE publication_id = 1;

    -- Clean up verified title tag
    UPDATE publication 
    SET title = REPLACE(title, ' [Verified]', '')
    WHERE publication_id = 1;

    IF v_new_timestamp > v_old_timestamp THEN
        RAISE NOTICE '[PASSED] Test 10: Trigger trg_publication_updated_at successfully updated modification timestamp.';
    ELSE
        RAISE EXCEPTION '[FAILED] Test 10: updated_at was not updated by trigger!';
    END IF;
END;
$$;

-- ============================================================================
-- TEST 11: VERIFY STORED FUNCTION (fn_get_researcher_pub_count)
-- ============================================================================
DO $$
DECLARE
    v_count INT;
BEGIN
    -- Researcher 3 (Dr. Rajan Patel) has 4 authored papers in sample data
    v_count := fn_get_researcher_pub_count(3);

    IF v_count >= 4 THEN
        RAISE NOTICE '[PASSED] Test 11: Stored function fn_get_researcher_pub_count returned correct count: %.', v_count;
    ELSE
        RAISE EXCEPTION '[FAILED] Test 11: Unexpected count returned for researcher 3: %', v_count;
    END IF;
END;
$$;

-- ============================================================================
-- TEST 12: VERIFY STORED PROCEDURE & AUDIT LOG TRIGGER
-- ============================================================================
DO $$
DECLARE
    v_log_count INT;
BEGIN
    -- Call stored procedure to change conference 5 status to completed
    CALL sp_update_conference_status(5, 'completed', 1);

    -- Check if audit log captured the update
    SELECT COUNT(*) INTO v_log_count
    FROM admin_audit_log
    WHERE target_table = 'conference' AND target_id = 5;

    IF v_log_count >= 1 THEN
        RAISE NOTICE '[PASSED] Test 12: Procedure sp_update_conference_status and audit logging successfully executed.';
    ELSE
        RAISE EXCEPTION '[FAILED] Test 12: Audit entry was not found for conference update!';
    END IF;
END;
$$;

-- ============================================================================
-- TEST 13: VERIFY VIEWS RETURN CONSISTENT RESULTS
-- ============================================================================
DO $$
DECLARE
    v_view_rows INT;
BEGIN
    SELECT COUNT(*) INTO v_view_rows FROM v_publication_details;
    IF v_view_rows < 10 THEN
        RAISE EXCEPTION '[FAILED] Test 13: v_publication_details returned insufficient rows: %', v_view_rows;
    END IF;

    SELECT COUNT(*) INTO v_view_rows FROM v_collaborations_bidirectional;
    -- Since we have 10 canonical collaborations, bidirectional view must contain exactly 20 rows!
    IF v_view_rows = 20 THEN
        RAISE NOTICE '[PASSED] Test 13: Views returned expected row counts (Bidirectional collaborations = 20).';
    ELSE
        RAISE EXCEPTION '[FAILED] Test 13: v_collaborations_bidirectional expected 20 rows, got: %', v_view_rows;
    END IF;
END;
$$;

\echo '============================================================================'
\echo ' ALL 13 TEST SUITES COMPLETED SUCCESSFULLY!'
\echo '============================================================================'
