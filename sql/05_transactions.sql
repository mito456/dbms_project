-- ============================================================================
-- Research Collaboration & Publication Intelligence System
-- File: 05_transactions.sql
-- Description: ACID properties, transactions, rollbacks, savepoints, and
--              introductory concurrency control for DBMS Level 3.
-- ============================================================================

-- ============================================================================
-- OVERVIEW OF ACID PROPERTIES IN THIS SYSTEM:
-- - Atomicity: All operations in a transaction succeed, or none take effect.
-- - Consistency: Constraints (FK, CHECK, UNIQUE) are never violated.
-- - Isolation: Concurrent queries see predictable snapshots (PostgreSQL default: READ COMMITTED).
-- - Durability: Committed transactions persist even in the event of power/system crashes.
-- ============================================================================

-- ============================================================================
-- SCENARIO 1: ATOMIC INSERTION WITH COMMIT
-- Business Case: A researcher submits a new paper with multiple co-authors
-- and associated topics. All three entities must be saved together atomically.
-- ============================================================================
BEGIN;

-- Step 1: Insert the publication record
INSERT INTO publication (title, abstract, publication_date, url, doi)
VALUES (
    'Towards Real-Time Neural Indexing in Relational Databases',
    'Exploring deep learned index structures embedded directly inside transactional storage engines.',
    '2025-01-15',
    'https://openres.org/papers/2025/neural-indexing',
    '10.1145/3700000.3700010'
);

-- Step 2: Associate authors with ordinal ranks
-- Using currval / MAX identity to link the newly inserted paper
INSERT INTO authorship (researcher_id, publication_id, author_order)
VALUES 
    (3, (SELECT MAX(publication_id) FROM publication), 1), -- Dr. Rajan Patel (Lead Author)
    (8, (SELECT MAX(publication_id) FROM publication), 2); -- Dr. Elena Rostova (2nd Author)

-- Step 3: Associate research topics
INSERT INTO publication_topic (publication_id, topic_id)
VALUES 
    ((SELECT MAX(publication_id) FROM publication), 2), -- Vector Databases & Search
    ((SELECT MAX(publication_id) FROM publication), 3); -- Query Optimization

-- Verify within transaction before committing
SELECT 
    p.publication_id, 
    p.title, 
    STRING_AGG(r.name, ', ' ORDER BY a.author_order) AS co_authors
FROM publication p
JOIN authorship a ON p.publication_id = a.publication_id
JOIN researcher r ON a.researcher_id = r.researcher_id
WHERE p.doi = '10.1145/3700000.3700010'
GROUP BY p.publication_id, p.title;

-- All operations succeeded without constraint violations: COMMIT
COMMIT;

-- ============================================================================
-- SCENARIO 2: INTENTIONAL ERROR AND ROLLBACK (ATOMICITY GUARANTEE)
-- Business Case: A transaction attempts to create a publication, but fails
-- because an author order constraint is violated (two authors claiming order=1).
-- Without transactions, the publication would be orphaned without authors.
-- With transactions, ROLLBACK ensures the publication is NOT inserted.
-- ============================================================================
BEGIN;

-- Step 1: Insert publication record
INSERT INTO publication (title, abstract, publication_date, url, doi)
VALUES (
    'Faulty Transaction Test: Orphaned Paper Prevention',
    'This paper should never exist in the database after the transaction aborts.',
    '2025-02-01',
    'https://openres.org/papers/2025/faulty-tx',
    '10.9999/faulty.paper.101'
);

-- Step 2: Attempt duplicate author_order (Constraint Violation!)
-- Both authors are assigned author_order = 1, violating uq_publication_author_order!
DO $$
BEGIN
    INSERT INTO authorship (researcher_id, publication_id, author_order)
    VALUES 
        (1, (SELECT MAX(publication_id) FROM publication), 1),
        (2, (SELECT MAX(publication_id) FROM publication), 1); -- Violates uq_publication_author_order
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Constraint violation detected! Aborting transaction to prevent partial insert: %', SQLERRM;
END;
$$;

-- In standard application workflows or scripts, any unhandled error triggers ROLLBACK:
ROLLBACK;

-- Verification: Ensure the publication was NOT persisted
SELECT COUNT(*) AS should_be_zero
FROM publication 
WHERE doi = '10.9999/faulty.paper.101';

-- ============================================================================
-- SCENARIO 3: SAVEPOINTS (PARTIAL ROLLBACK WITHIN A TRANSACTION)
-- Business Case: When importing batch records, if one optional tag fails,
-- we rollback to a savepoint rather than aborting the entire paper creation.
-- ============================================================================
BEGIN;

-- Step 1: Create a publication
INSERT INTO publication (title, abstract, publication_date, url, doi)
VALUES (
    'Resilient Batch Processing with Savepoints',
    'Demonstration of partial rollback in transactional data pipelines.',
    '2025-03-10',
    'https://openres.org/papers/2025/savepoint-demo',
    '10.1109/DEMO.2025.5555'
);

-- Step 2: Establish a safe checkpoint
SAVEPOINT publication_created;

-- Step 3: Attempt to attach a non-existent topic ID (Foreign Key Violation)
DO $$
BEGIN
    INSERT INTO publication_topic (publication_id, topic_id)
    VALUES ((SELECT MAX(publication_id) FROM publication), 999999); -- Does not exist!
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'Caught invalid topic FK. Rolling back to savepoint without losing paper.';
END;
$$;

-- Rollback the failed topic attempt to our checkpoint
ROLLBACK TO SAVEPOINT publication_created;

-- Step 4: Insert valid topic instead
INSERT INTO publication_topic (publication_id, topic_id)
VALUES ((SELECT MAX(publication_id) FROM publication), 1); -- Topic 1: Distributed Consensus

-- Commit valid work
COMMIT;

-- Verify that the paper and valid topic survived
SELECT p.title, t.name AS topic_name
FROM publication p
JOIN publication_topic pt ON p.publication_id = pt.publication_id
JOIN research_topic t ON pt.topic_id = t.topic_id
WHERE p.doi = '10.1109/DEMO.2025.5555';

-- ============================================================================
-- SCENARIO 4: CONCURRENCY CONTROL & ROW LOCKING (FOR UPDATE)
-- Business Case: Two administrators concurrently attempting to update the
-- same conference. SELECT ... FOR UPDATE acquires an exclusive row-level lock.
-- ============================================================================
BEGIN;

-- Lock the target conference row exclusively until this transaction concludes.
-- Any concurrent transaction trying to UPDATE this conference will wait (block).
SELECT conference_id, name, status, submission_deadline
FROM conference
WHERE conference_id = 1
FOR UPDATE;

-- Safely perform update
UPDATE conference
SET status = 'upcoming'
WHERE conference_id = 1;

COMMIT; -- Row lock released here
