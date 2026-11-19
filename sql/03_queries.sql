-- ============================================================================
-- Research Collaboration & Publication Intelligence System
-- File: 03_queries.sql
-- Description: Basic & complex SQL queries covering joins, aggregations,
--              subqueries, CTEs, and window functions for DBMS Level 3.
-- ============================================================================

-- ============================================================================
-- QUERY 1: Find all publications written by a specific researcher
-- Target: Dr. Rajan Patel (researcher_id = 3)
-- Concept: Inner join across a many-to-many relationship via junction table.
-- ============================================================================
SELECT 
    p.publication_id,
    p.title,
    p.publication_date,
    p.doi,
    a.author_order
FROM publication p
JOIN authorship a ON p.publication_id = a.publication_id
JOIN researcher r ON a.researcher_id = r.researcher_id
WHERE r.name = 'Dr. Rajan Patel'
ORDER BY p.publication_date DESC, a.author_order ASC;

-- ============================================================================
-- QUERY 2: Find all researchers associated with a particular publication
-- Target: 'Adaptive Indexing for High-Dimensional Vector Spaces' (publication_id = 1)
-- Concept: Joining publication to authorship to researcher, ordered by attribution.
-- ============================================================================
SELECT 
    a.author_order,
    r.researcher_id,
    r.name AS author_name,
    r.institution,
    r.email
FROM authorship a
JOIN researcher r ON a.researcher_id = r.researcher_id
JOIN publication p ON a.publication_id = p.publication_id
WHERE p.title = 'Adaptive Indexing for High-Dimensional Vector Spaces'
ORDER BY a.author_order ASC;

-- ============================================================================
-- QUERY 3: Find researchers interested in a particular research topic
-- Target: 'Vector Databases & Search'
-- Concept: M:N filtering through researcher_topic with interest level sorting.
-- ============================================================================
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    rt.interest_level,
    t.name AS topic_name
FROM researcher r
JOIN researcher_topic rt ON r.researcher_id = rt.researcher_id
JOIN research_topic t ON rt.topic_id = t.topic_id
WHERE t.name = 'Vector Databases & Search'
ORDER BY 
    CASE rt.interest_level 
        WHEN 'expert' THEN 1 
        WHEN 'advanced' THEN 2 
        WHEN 'intermediate' THEN 3 
        ELSE 4 
    END, 
    r.name ASC;

-- ============================================================================
-- QUERY 4: Find publications associated with a topic
-- Target: 'Post-Quantum Cryptography'
-- Concept: M:N join between publication and research_topic.
-- ============================================================================
SELECT 
    p.publication_id,
    p.title,
    p.publication_date,
    p.doi,
    t.name AS topic_name,
    t.category
FROM publication p
JOIN publication_topic pt ON p.publication_id = pt.publication_id
JOIN research_topic t ON pt.topic_id = t.topic_id
WHERE t.name = 'Post-Quantum Cryptography'
ORDER BY p.publication_date DESC;

-- ============================================================================
-- QUERY 5: Find upcoming conferences ordered by submission deadline
-- Concept: Filtering on status and date predicates with chronological ordering.
-- ============================================================================
SELECT 
    c.conference_id,
    c.name AS conference_name,
    c.location,
    c.submission_deadline,
    c.start_date,
    c.end_date,
    (c.submission_deadline - CURRENT_DATE) AS days_remaining_to_submit
FROM conference c
WHERE c.status = 'upcoming' 
  AND c.submission_deadline >= CURRENT_DATE
ORDER BY c.submission_deadline ASC;

-- ============================================================================
-- QUERY 6: Find conferences associated with a researcher's interests
-- Target: Dr. Mei-Ling Zhou (researcher_id = 2)
-- Concept: Multi-hop join: Researcher -> ResearcherTopic -> Topic -> ConferenceTopic -> Conference.
-- Uses DISTINCT because multiple shared topics could map to the same conference.
-- ============================================================================
SELECT DISTINCT
    c.conference_id,
    c.name AS conference_name,
    c.location,
    c.submission_deadline,
    c.status,
    t.name AS matched_interest_topic
FROM researcher r
JOIN researcher_topic rt ON r.researcher_id = rt.researcher_id
JOIN research_topic t ON rt.topic_id = t.topic_id
JOIN conference_topic ct ON t.topic_id = ct.topic_id
JOIN conference c ON ct.conference_id = c.conference_id
WHERE r.name = 'Dr. Mei-Ling Zhou'
  AND c.status IN ('upcoming', 'ongoing')
ORDER BY c.submission_deadline ASC;

-- ============================================================================
-- QUERY 7: Count publications per researcher (including those with 0)
-- Concept: Outer Join (LEFT JOIN) with GROUP BY and aggregate COUNT.
-- Using COUNT(a.publication_id) ensures researchers with 0 papers count as 0, not 1.
-- ============================================================================
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    COUNT(a.publication_id) AS total_publications
FROM researcher r
LEFT JOIN authorship a ON r.researcher_id = a.researcher_id
GROUP BY r.researcher_id, r.name, r.institution
ORDER BY total_publications DESC, r.name ASC;

-- ============================================================================
-- QUERY 8: Find researchers who have authored more than a specified threshold
-- Target: Researchers with > 2 publications
-- Concept: Aggregation with HAVING clause filtering post-aggregation groups.
-- ============================================================================
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    COUNT(a.publication_id) AS publication_count
FROM researcher r
JOIN authorship a ON r.researcher_id = a.researcher_id
GROUP BY r.researcher_id, r.name, r.institution
HAVING COUNT(a.publication_id) > 2
ORDER BY publication_count DESC;

-- ============================================================================
-- QUERY 9: Find projects and their participating researchers with roles
-- Concept: Multi-table join across project, researcher_project, and researcher.
-- ============================================================================
SELECT 
    p.project_id,
    p.name AS project_name,
    p.status AS project_status,
    r.name AS researcher_name,
    r.institution,
    rp.role AS project_role,
    rp.joined_date
FROM project p
JOIN researcher_project rp ON p.project_id = rp.project_id
JOIN researcher r ON rp.researcher_id = r.researcher_id
ORDER BY p.name ASC, rp.joined_date ASC;

-- ============================================================================
-- QUERY 10: Find topics shared by multiple researchers (with researcher counts)
-- Concept: Aggregation on junction table to discover common community interests.
-- ============================================================================
SELECT 
    t.topic_id,
    t.name AS topic_name,
    t.category,
    COUNT(rt.researcher_id) AS interested_researchers_count
FROM research_topic t
JOIN researcher_topic rt ON t.topic_id = rt.topic_id
GROUP BY t.topic_id, t.name, t.category
HAVING COUNT(rt.researcher_id) >= 2
ORDER BY interested_researchers_count DESC, t.name ASC;

-- ============================================================================
-- QUERY 11: Find potential collaborators sharing research interests
-- Target: Dr. Aris Thorne (researcher_id = 1)
-- Concept: Self-join on researcher_topic to discover peers with shared topics,
--          excluding the target researcher.
-- ============================================================================
SELECT 
    other_r.researcher_id,
    other_r.name AS potential_collaborator,
    other_r.institution,
    COUNT(other_rt.topic_id) AS shared_topic_count,
    STRING_AGG(t.name, ', ' ORDER BY t.name) AS shared_topics
FROM researcher_topic target_rt
JOIN researcher_topic other_rt ON target_rt.topic_id = other_rt.topic_id
JOIN researcher other_r ON other_rt.researcher_id = other_r.researcher_id
JOIN research_topic t ON target_rt.topic_id = t.topic_id
JOIN researcher target_r ON target_rt.researcher_id = target_r.researcher_id
WHERE target_r.name = 'Dr. Aris Thorne'
  AND other_r.researcher_id <> target_r.researcher_id
GROUP BY other_r.researcher_id, other_r.name, other_r.institution
ORDER BY shared_topic_count DESC, potential_collaborator ASC;

-- ============================================================================
-- QUERY 12: Find publications associated with multiple selected topics
-- Target: Publications tagged with BOTH 'Vector Databases & Search' AND 'Query Optimization'
-- Concept: Relational Division using GROUP BY and HAVING COUNT(DISTINCT).
-- ============================================================================
SELECT 
    p.publication_id,
    p.title,
    p.publication_date,
    p.doi
FROM publication p
JOIN publication_topic pt ON p.publication_id = pt.publication_id
JOIN research_topic t ON pt.topic_id = t.topic_id
WHERE t.name IN ('Vector Databases & Search', 'Query Optimization')
GROUP BY p.publication_id, p.title, p.publication_date, p.doi
HAVING COUNT(DISTINCT t.topic_id) = 2
ORDER BY p.publication_date DESC;

-- ============================================================================
-- QUERY 13: Nested Subquery Demonstration
-- Concept: Independent subquery in the WHERE IN clause.
-- Goal: Find all researchers who have never worked on any active project.
-- ============================================================================
SELECT 
    r.researcher_id,
    r.name,
    r.email,
    r.institution
FROM researcher r
WHERE r.researcher_id NOT IN (
    -- Subquery: distinct researchers participating in active projects
    SELECT DISTINCT rp.researcher_id
    FROM researcher_project rp
    JOIN project pr ON rp.project_id = pr.project_id
    WHERE pr.status = 'active'
)
ORDER BY r.name ASC;

-- ============================================================================
-- QUERY 14: Correlated Subquery Demonstration
-- Concept: Subquery references the outer query row (r.researcher_id).
-- Goal: Display each researcher alongside their most recent publication title.
-- ============================================================================
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    (
        -- Correlated subquery: executed once for each researcher row
        SELECT p.title
        FROM authorship a
        JOIN publication p ON a.publication_id = p.publication_id
        WHERE a.researcher_id = r.researcher_id
        ORDER BY p.publication_date DESC, p.publication_id DESC
        LIMIT 1
    ) AS latest_publication_title
FROM researcher r
ORDER BY r.name ASC;

-- ============================================================================
-- QUERY 15: Common Table Expression (CTE) Demonstration
-- Concept: Modular query breakdown using WITH clause.
-- Goal: Calculate institutional research impact by aggregating author papers.
-- ============================================================================
WITH researcher_paper_counts AS (
    -- Step 1: Count publications per researcher
    SELECT 
        r.researcher_id,
        r.name,
        r.institution,
        COUNT(a.publication_id) AS paper_count
    FROM researcher r
    LEFT JOIN authorship a ON r.researcher_id = a.researcher_id
    GROUP BY r.researcher_id, r.name, r.institution
),
institution_metrics AS (
    -- Step 2: Aggregate by institution
    SELECT 
        institution,
        COUNT(researcher_id) AS total_researchers,
        SUM(paper_count) AS total_institution_papers,
        ROUND(AVG(paper_count), 2) AS avg_papers_per_researcher
    FROM researcher_paper_counts
    WHERE institution IS NOT NULL
    GROUP BY institution
)
-- Step 3: Final presentation
SELECT 
    institution,
    total_researchers,
    total_institution_papers,
    avg_papers_per_researcher
FROM institution_metrics
ORDER BY total_institution_papers DESC, institution ASC;

-- ============================================================================
-- QUERY 16: Window Function Demonstration
-- Concept: DENSE_RANK() and ROW_NUMBER() over an aggregate partition.
-- Goal: Rank researchers globally by publication volume without collapsing rows.
-- ============================================================================
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    COUNT(a.publication_id) AS total_papers,
    DENSE_RANK() OVER (ORDER BY COUNT(a.publication_id) DESC) AS productivity_rank,
    ROW_NUMBER() OVER (ORDER BY COUNT(a.publication_id) DESC, r.name ASC) AS sequence_id
FROM researcher r
LEFT JOIN authorship a ON r.researcher_id = a.researcher_id
GROUP BY r.researcher_id, r.name, r.institution
ORDER BY productivity_rank ASC, sequence_id ASC;
