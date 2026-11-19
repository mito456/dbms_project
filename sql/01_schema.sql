-- ============================================================================
-- Research Collaboration & Publication Intelligence System
-- File: 01_schema.sql
-- Description: DDL script creating all core tables, constraints, keys, & rules.
-- Target RDBMS: PostgreSQL 14+ (Compatible with pgvector)
-- ============================================================================

-- Ensure the pgvector extension is enabled
CREATE EXTENSION IF NOT EXISTS vector;

-- NOTE ON DATABASE CREATION:
-- In PostgreSQL, CREATE DATABASE cannot run inside a multi-statement transaction block.
-- If creating manually outside Docker, execute:
--   CREATE DATABASE research_db;
--   \c research_db;
-- (When using docker-compose.yml, this database is initialized automatically).

-- ----------------------------------------------------------------------------
-- Cleanup / Idempotent Reset
-- Drop junction tables first, then primary entities (reverse dependency order)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS conference_topic CASCADE;
DROP TABLE IF EXISTS publication_topic CASCADE;
DROP TABLE IF EXISTS researcher_topic CASCADE;
DROP TABLE IF EXISTS researcher_project CASCADE;
DROP TABLE IF EXISTS collaboration CASCADE;
DROP TABLE IF EXISTS authorship CASCADE;
DROP TABLE IF EXISTS research_topic CASCADE;
DROP TABLE IF EXISTS conference CASCADE;
DROP TABLE IF EXISTS project CASCADE;
DROP TABLE IF EXISTS publication CASCADE;
DROP TABLE IF EXISTS researcher CASCADE;
DROP TABLE IF EXISTS admin CASCADE;
DROP TABLE IF EXISTS admin_audit_log CASCADE;

-- ============================================================================
-- ENTITY 1: ADMIN
-- Stores administrator accounts responsible for system moderation and data curation.
-- ============================================================================
CREATE TABLE admin (
    admin_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'admin',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_admin_email UNIQUE (email),
    CONSTRAINT chk_admin_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_admin_role CHECK (role IN ('super_admin', 'admin', 'moderator'))
);

COMMENT ON TABLE admin IS 'Administrative personnel managing platform metadata and users';
COMMENT ON COLUMN admin.password_hash IS 'Application-level hash (e.g., Argon2id/bcrypt); plaintext passwords are never stored';

-- ============================================================================
-- ENTITY 2: RESEARCHER (Represents USER)
-- Stores researcher profiles, academic affiliations, and credentials.
-- Renamed from "USER" to avoid collision with PostgreSQL reserved keyword 'USER'.
-- ============================================================================
CREATE TABLE researcher (
    researcher_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    institution VARCHAR(200),
    bio TEXT,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_researcher_email UNIQUE (email),
    CONSTRAINT chk_researcher_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE researcher IS 'Primary academic user entity representing researchers and scholars';
COMMENT ON COLUMN researcher.password_hash IS 'Application-level secure salted hash; login authentication is handled at the server tier';

-- ============================================================================
-- ENTITY 3: PUBLICATION
-- Stores academic articles, journal papers, conference proceedings, and preprints.
-- ============================================================================
CREATE TABLE publication (
    publication_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    abstract TEXT,
    publication_date DATE NOT NULL,
    url TEXT,
    doi VARCHAR(100),
    embedding vector(768),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    -- In PostgreSQL, standard UNIQUE constraints allow multiple NULL entries while ensuring non-null values are unique.
    CONSTRAINT uq_publication_doi UNIQUE (doi),
    CONSTRAINT chk_publication_date_valid CHECK (publication_date <= CURRENT_DATE + INTERVAL '1 year')
);

COMMENT ON TABLE publication IS 'Peer-reviewed papers, preprints, and research articles';
COMMENT ON COLUMN publication.doi IS 'Digital Object Identifier; unique when supplied, nullable for unpublished work';

-- ============================================================================
-- ENTITY 4: PROJECT
-- Stores research initiatives, funded grants, and academic projects.
-- ============================================================================
CREATE TABLE project (
    project_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_project_status CHECK (status IN ('planned', 'active', 'completed', 'on_hold', 'cancelled')),
    CONSTRAINT chk_project_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE project IS 'Collaborative research initiatives and funded academic grants';
COMMENT ON COLUMN project.status IS 'Project lifecycle status: planned, active, completed, on_hold, cancelled';

-- ============================================================================
-- ENTITY 5: CONFERENCE
-- Stores academic conferences, workshops, and symposiums.
-- ============================================================================
CREATE TABLE conference (
    conference_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    location VARCHAR(200),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    submission_deadline DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'upcoming',
    url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_conference_status CHECK (status IN ('upcoming', 'ongoing', 'completed', 'postponed', 'cancelled')),
    CONSTRAINT chk_conference_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_conference_deadline CHECK (submission_deadline <= start_date)
);

COMMENT ON TABLE conference IS 'Academic conferences with submission timelines and location information';

-- ============================================================================
-- ENTITY 6: RESEARCH_TOPIC
-- Stores taxonomical research domains, subjects, and keywords.
-- ============================================================================
CREATE TABLE research_topic (
    topic_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT uq_topic_name UNIQUE (name)
);

COMMENT ON TABLE research_topic IS 'Standardized research areas and disciplines across the platform';

-- ============================================================================
-- ENTITY 7: AUTHORSHIP (Many-to-Many: RESEARCHER <-> PUBLICATION)
-- Maps researchers to their authored publications with explicit author order.
-- ============================================================================
CREATE TABLE authorship (
    researcher_id BIGINT NOT NULL,
    publication_id BIGINT NOT NULL,
    author_order INT NOT NULL DEFAULT 1,

    -- Primary Key: Composite key prevents duplicate author entries per publication
    PRIMARY KEY (researcher_id, publication_id),

    -- Foreign Keys:
    -- ON DELETE CASCADE ensures orphaned authorship associations are removed if a researcher or publication is deleted
    CONSTRAINT fk_authorship_researcher FOREIGN KEY (researcher_id)
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT fk_authorship_publication FOREIGN KEY (publication_id)
        REFERENCES publication(publication_id) ON DELETE CASCADE,

    -- Constraints
    CONSTRAINT chk_author_order_positive CHECK (author_order > 0),
    CONSTRAINT uq_publication_author_order UNIQUE (publication_id, author_order)
);

COMMENT ON TABLE authorship IS 'Attribution connecting researchers to their published literature';
COMMENT ON COLUMN authorship.author_order IS 'Ordinal ranking (1 = first author / lead investigator)';

-- ============================================================================
-- ENTITY 8: COLLABORATION (Many-to-Many: RESEARCHER <-> RESEARCHER)
-- Stores calculated or discovered research partnerships between two scholars.
-- ============================================================================
CREATE TABLE collaboration (
    collaboration_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    researcher_id_1 BIGINT NOT NULL,
    researcher_id_2 BIGINT NOT NULL,
    similarity_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_collaboration_researcher_1 FOREIGN KEY (researcher_id_1)
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT fk_collaboration_researcher_2 FOREIGN KEY (researcher_id_2)
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,

    -- Integrity Constraints:
    -- 1) Prevent self-collaboration: researcher cannot pair with themselves
    -- 2) Prevent duplicate symmetric pairs: forces researcher_id_1 to be strictly smaller than researcher_id_2
    --    This guarantees (1, 2) can exist, but (2, 1) is rejected, eliminating duplicate relationships.
    CONSTRAINT chk_collaboration_no_self CHECK (researcher_id_1 < researcher_id_2),
    CONSTRAINT uq_collaboration_pair UNIQUE (researcher_id_1, researcher_id_2),

    -- 3) Similarity score normalized between 0.0000 and 1.0000
    CONSTRAINT chk_collaboration_score_range CHECK (similarity_score >= 0.0000 AND similarity_score <= 1.0000)
);

COMMENT ON TABLE collaboration IS 'Undirected similarity/co-authorship ties between two distinct researchers';
COMMENT ON COLUMN collaboration.similarity_score IS 'Computed interest/co-authorship alignment score between 0.0 and 1.0';

-- ============================================================================
-- ENTITY 9: RESEARCHER_PROJECT (Many-to-Many: RESEARCHER <-> PROJECT)
-- Associates researchers with projects they contribute to.
-- ============================================================================
CREATE TABLE researcher_project (
    researcher_id BIGINT NOT NULL,
    project_id BIGINT NOT NULL,
    role VARCHAR(100) NOT NULL DEFAULT 'Contributor',
    joined_date DATE NOT NULL DEFAULT CURRENT_DATE,

    PRIMARY KEY (researcher_id, project_id),

    CONSTRAINT fk_researcher_project_researcher FOREIGN KEY (researcher_id)
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT fk_researcher_project_project FOREIGN KEY (project_id)
        REFERENCES project(project_id) ON DELETE CASCADE
);

COMMENT ON TABLE researcher_project IS 'Membership and roles of researchers within ongoing or past projects';

-- ============================================================================
-- ENTITY 10: RESEARCHER_TOPIC (Many-to-Many: RESEARCHER <-> RESEARCH_TOPIC)
-- Records the subject interests and expertise levels of researchers.
-- ============================================================================
CREATE TABLE researcher_topic (
    researcher_id BIGINT NOT NULL,
    topic_id BIGINT NOT NULL,
    interest_level VARCHAR(20) NOT NULL DEFAULT 'intermediate',

    PRIMARY KEY (researcher_id, topic_id),

    CONSTRAINT fk_researcher_topic_researcher FOREIGN KEY (researcher_id)
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT fk_researcher_topic_topic FOREIGN KEY (topic_id)
        REFERENCES research_topic(topic_id) ON DELETE CASCADE,

    CONSTRAINT chk_interest_level CHECK (interest_level IN ('beginner', 'intermediate', 'advanced', 'expert'))
);

COMMENT ON TABLE researcher_topic IS 'Declared subject interests and proficiency levels for researchers';

-- ============================================================================
-- ENTITY 11: PUBLICATION_TOPIC (Many-to-Many: PUBLICATION <-> RESEARCH_TOPIC)
-- Tags academic papers with relevant research topics.
-- ============================================================================
CREATE TABLE publication_topic (
    publication_id BIGINT NOT NULL,
    topic_id BIGINT NOT NULL,

    PRIMARY KEY (publication_id, topic_id),

    CONSTRAINT fk_publication_topic_publication FOREIGN KEY (publication_id)
        REFERENCES publication(publication_id) ON DELETE CASCADE,
    CONSTRAINT fk_publication_topic_topic FOREIGN KEY (topic_id)
        REFERENCES research_topic(topic_id) ON DELETE CASCADE
);

COMMENT ON TABLE publication_topic IS 'Subject classification of research publications';

-- ============================================================================
-- ENTITY 12: CONFERENCE_TOPIC (Many-to-Many: CONFERENCE <-> RESEARCH_TOPIC)
-- Tags conferences with topics covered in their call for papers.
-- ============================================================================
CREATE TABLE conference_topic (
    conference_id BIGINT NOT NULL,
    topic_id BIGINT NOT NULL,

    PRIMARY KEY (conference_id, topic_id),

    CONSTRAINT fk_conference_topic_conference FOREIGN KEY (conference_id)
        REFERENCES conference(conference_id) ON DELETE CASCADE,
    CONSTRAINT fk_conference_topic_topic FOREIGN KEY (topic_id)
        REFERENCES research_topic(topic_id) ON DELETE CASCADE
);

COMMENT ON TABLE conference_topic IS 'Call-for-papers subject tracks for academic conferences';

-- ============================================================================
-- SUPPLEMENTAL TABLE: ADMIN_AUDIT_LOG
-- Keeps an immutable audit trail of administrative modifications (for Part 5 trigger).
-- ============================================================================
CREATE TABLE admin_audit_log (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admin_id BIGINT REFERENCES admin(admin_id) ON DELETE SET NULL,
    target_table VARCHAR(50) NOT NULL,
    target_id BIGINT NOT NULL,
    action_type VARCHAR(20) NOT NULL, -- e.g., 'INSERT', 'UPDATE', 'DELETE'
    old_values JSONB,
    new_values JSONB,
    performed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_audit_action CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE'))
);

COMMENT ON TABLE admin_audit_log IS 'Immutable audit ledger recording admin actions across publications and conferences';
