# Department of Computer Science and Engineering

## (AI & ML)

### B. Tech. CSE - 5th Semester

### Aug – Dec 2025

### UE23CS351A

### DATABASE MANAGEMENT SYSTEMS (DBMS)

### PROJECT REPORT on

# Research Collaboration & Publication Intelligence System

**Submitted by:**

| SRN                     | Name               | Section |
| :---------------------- | :----------------- | :------ |
| **PES1UG24AM037** | ANANYA RAGHAVENDRA | 5 'A'   |
| **PES1UG24AM038** | ANANYA S           | 5 'A'   |

**Class of Prof. Smitha G. R.**  
**Lab Faculty: Prof. Rati D. Joshi**

---

## Abstract

The **Research Collaboration & Publication Intelligence System** is an end-to-end academic discovery and networking platform engineered to streamline scientific literature exploration, conference deadline tracking, and automated collaborator matching. Traditional academic systems frequently suffer from siloed datasets, rigid keyword search paradigms, and slow analytical discovery pipelines. To resolve these limitations, this project designs and implements an enterprise-grade hybrid database architecture combining a strongly typed **PostgreSQL 16** relational core with **pgvector** neural semantic indexing and **MongoDB 8** document-based audit trail tracking. The relational tier guarantees strict ACID transactions, entity constraints, domain integrity checks, and composite foreign key cascades across twelve relational tables. High-dimensional 768-dimensional dense vector embeddings generated via `BAAI/bge-base-en-v1.5` enable sub-millisecond semantic search via Hierarchical Navigable Small World (HNSW) indexing using cosine distance operators. Stored PL/pgSQL functions calculate dynamic Jaccard topic similarity coefficients, while database triggers automate real-time timestamp updates and administrative audit logging. The database integrates with a high-throughput **FastAPI** backend enforcing JSON Web Token (JWT) role-based access control (`admin`, `moderator`, and `researcher`) and a reactive web interface built with modern JavaScript components. This report details the comprehensive lifecycle of the project, including User Requirements Specifications, conceptual E-R and Relational Modeling, comprehensive DDL/DML implementations, advanced database programmability, vector database operations, Next.js/React project topology, and evaluation rubrics.

---

## Table of Contents

| Sl. No        | Topic                                                      | Page No. |
| :------------ | :--------------------------------------------------------- | :------- |
| **1.**  | Introduction & Problem Statement                           | 3        |
| **2.**  | User Requirements Specification & Tech Stack Justification | 4        |
| **3.**  | E-R Model (Entities, Attributes, and ERD Diagram)          | 6        |
| **4.**  | Relational Model & Schema Diagram                          | 8        |
| **5.**  | SQL DDL Statements & Database Constraints                  | 10       |
| **6.**  | SQL DML Statements & Advanced Query Demonstrations         | 14       |
| **7.**  | NoSQL / Vector Database Commands & Operations              | 18       |
| **8.**  | Results & Resulting Tables' Screenshots / CLI Outputs      | 21       |
| **9.**  | Project Tree Structure & Application Architecture          | 24       |
| **10.** | Application Code Snippets & Interface Demonstration        | 26       |
| **11.** | Evaluation Rubrics & Completion Status                     | 29       |

---

## 1. Introduction & Problem Statement

### Problem Statement & Short Description

In modern higher education and global scientific research environments, researchers and scholars encounter significant impediments in identifying potential collaborators across intersecting disciplines, managing tracking cycles for conference call-for-papers (CFPs), and discovering domain-relevant literature. Standard relational catalog search engines rely exclusively on lexical keyword matching (e.g., standard SQL `LIKE '%pattern%'` or full-text boolean search). These lexical approaches fail to capture latent conceptual relationships, synonymy, or cross-domain thematic affinities (for instance, missing papers on "Deep Metric Learning" when searching for "Vector Similarity Embeddings").

Furthermore, institutional administrative governance demands non-blocking, tamper-evident audit logging for user interactions, data modifications, and privilege elevation without introducing transactional deadlocks or write latency into high-frequency primary relational tables.

The **Research Collaboration & Publication Intelligence System** addresses this problem by designing a multi-model data management architecture:

1. **Core Relational Model**: Standardized relational design in PostgreSQL 16 maintaining referential integrity across researchers, publications, institutions, topics, conferences, and collaborative grants.
2. **AI-Powered Vector Semantic Search**: Seamless integration of the PostgreSQL `pgvector` extension to store 768-dimensional document embeddings, enabling cosine similarity queries over research abstracts.
3. **Document-Oriented Logging Engine**: Non-blocking asynchronous logging in MongoDB for capturing detailed user activity and security audits.
4. **Decoupled API & Web Tier**: Secure RESTful microservices with JWT-based Role-Based Access Control (RBAC) powering an interactive user interface.

---

## 2. User Requirements Specification & Tech Stack Justification

### Functional Requirements

1. **User & Identity Management**: Secure authentication supporting multiple user roles (`super_admin`, `admin`, `moderator`, and `researcher`) with encrypted credential storage (Argon2id/bcrypt) and JWT session tokens.
2. **Publication & Authorship Management**: Structured cataloging of scholarly publications, DOI uniqueness verification, citation metadata, and ordered multi-author attribution tracking ($M:N$).
3. **Automated Collaborator Recommendation**: Relational discovery of potential research partners through shared thematic interests using Jaccard similarity indices and neural cosine distance across published works.
4. **Conference & Deadline Tracking**: Dynamic monitoring of academic conference schedules, submission deadlines, and automated status transition tracking (`upcoming`, `ongoing`, `completed`, `cancelled`).
5. **NoSQL Audit Trail**: Automated capture of read/write events, user search queries, and administrative data alterations in JSON/BSON format without hindering relational write performance.

---

### Tech Stack & Architectural Justifications

```
+-------------------------------------------------------------+
|                      React / Vite UI                        |
|           (TailwindCSS, Lucide Icons, Modern JS)            |
+------------------------------+------------------------------+
                               | HTTP / REST (JWT Bearer)
                               v
+-------------------------------------------------------------+
|                     FastAPI Backend                         |
|         (Python 3.11+, Pydantic V2, Psycopg 3 Pool)         |
+-------------------+---------------------+-------------------+
                    |                     |
     SQL + Vector   |                     | BSON Audit Logs
     (Port: 5433)   |                     | (Port: 27017)
                    v                     v
+-------------------------------+  +--------------------------+
|   PostgreSQL 16 + pgvector    |  |        MongoDB 8         |
|  - Relational Schema (13 tabs)|  | - Asynchronous Auditing  |
|  - 768-dim HNSW Vector Index  |  | - Flexible User Activity |
|  - Triggers, Functions, CTEs  |  | - JSON Schema Ingestion  |
+-------------------------------+  +--------------------------+
```

#### 1. Primary RDBMS: PostgreSQL 16

* **Justification**: Academic citations, researcher co-authorships, and conference schedules exhibit strict relational dependencies and require ACID compliance. PostgreSQL provides advanced table constraints, procedural PL/pgSQL capabilities, window functions, common table expressions (CTEs), and enterprise-grade concurrency through Multi-Version Concurrency Control (MVCC).

#### 2. Vector Database Extension: pgvector (768-dimensional)

* **Justification**: Storing vector embeddings directly within PostgreSQL eliminates the overhead of managing a separate vector database cluster (such as Pinecone or Milvus) and avoids data synchronization drift. `pgvector` supports Hierarchical Navigable Small World (HNSW) indexing using the `<=>` cosine distance operator, allowing single-query relational joins alongside semantic vector nearest-neighbor search.

#### 3. NoSQL Database: MongoDB 8

* **Justification for NoSQL**: User interaction tracking, search history, and audit telemetry produce polymorphic, semi-structured JSON payloads with varying metadata fields. Housing high-volume audit logs in a dedicated MongoDB instance isolates transactional tables from heavy write bursts and accommodates schema evolution without requiring `ALTER TABLE` migrations.

#### 4. Backend Service: FastAPI (Python 3.11+)

* **Justification**: High-performance asynchronous REST API framework natively compatible with Python's AI/ML ecosystem (`sentence-transformers`, `torch`, `huggingface`). Utilizes `psycopg` connection pools and Pydantic v2 schemas for request validation.

#### 5. Frontend Interface: Modern React / Next.js Component Architecture

* **Justification**: Component-based user interface enabling real-time data binding, authenticated route guards, dynamic search filters, and responsive visual cards for publications and researcher networks.

---

## 3. E-R (Entity-Relationship) Model

### List of Entities

#### Primary (Strong) Entities

1. **`admin`**: System administrators responsible for data curation, verification, and user moderation.
2. **`researcher`**: Academic users, authors, and scholars affiliated with universities or corporate research labs.
3. **`publication`**: Scholarly works, papers, journals, and preprints.
4. **`project`**: Funded or collaborative research initiatives.
5. **`conference`**: Academic venues and symposiums with fixed submission and event schedules.
6. **`research_topic`**: Standardized domain taxonomy and research areas (e.g., Computer Vision, Distributed DBMS).

#### Weak Entities & Subordinate Logs

1. **`admin_audit_log`** (*Weak Entity*): Tracks administrative actions. Depends existence-wise on the `admin` entity; if an administrator or system process executes a mutation, the log records old and new state snapshots in JSONB.

#### Associative / Junction Entities (M:N Relationship Resolvers)

1. **`authorship`**: Resolves $M:N$ between `researcher` and `publication`, storing author attribution sequence (`author_order`).
2. **`collaboration`**: Resolves peer collaboration partnerships between pairs of researchers (`researcher_id_1`, `researcher_id_2`) with computed `similarity_score`.
3. **`researcher_project`**: Resolves $M:N$ between `researcher` and `project` with contributor `role`.
4. **`researcher_topic`**: Resolves $M:N$ between `researcher` and `research_topic` with rated `interest_level`.
5. **`publication_topic`**: Resolves $M:N$ between `publication` and `research_topic`.
6. **`conference_topic`**: Resolves $M:N$ between `conference` and `research_topic`.

---

### Non-Simple Attributes (Composite, Multi-valued, and Derived)

1. **Composite Attributes**:
   - `conference_duration`: Derived/composed of `start_date` and `end_date`.
   - `author_identity`: Composed of `name`, `email`, and `institution` in user entities.
2. **Multi-valued Attributes**:
   - `authors`: Multi-valued attribute for publications, normalized into the `authorship` junction table.
   - `research_topics`: Multi-valued attribute for researchers and papers, normalized into `researcher_topic` and `publication_topic`.
3. **Derived Attributes**:
   - `total_publications`: Computed dynamically using `COUNT(publication_id)` via the `v_researcher_publication_counts` view.
   - `days_until_deadline`: Computed as `(submission_deadline - CURRENT_DATE)` in `v_upcoming_conferences`.
   - `similarity_score`: Computed via the Jaccard topic function `fn_calculate_topic_similarity`.

---

### Conceptual E-R Diagram (Crow's Foot Notation)

```
       +-------------------+                     +--------------------+
       |       ADMIN       |                     |  ADMIN_AUDIT_LOG   |
       +-------------------+                     +--------------------+
       | PK admin_id       |1------------------0<| PK audit_id        |
       |    name           |   (generates)       | FK admin_id        |
       |    email (UQ)     |                     |    old_values      |
       |    role           |                     |    new_values      |
       +-------------------+                     +--------------------+
                                                      
       +-------------------+                     +--------------------+
       |    RESEARCHER     |                     |    PUBLICATION     |
       +-------------------+                     +--------------------+
       | PK researcher_id  |1                   1| PK publication_id  |
       |    name           | \                 / |    title           |
       |    email (UQ)     |  \   AUTHORSHIP  /  |    publication_date|
       |    institution    |   >0-----------0<   |    doi (UQ)        |
       +-------------------+  /  |author_order|  |    embedding       |
         |1             1|   /   +------------+  +--------------------+
         |               |  /                               |1
         |  COLLABORATION| /                                |
         |   (Self-Ref)  |/                                 |
         | +-----------+ |                                  |
         +-|similarity |-+                                  |
           +-----------+                                    |
                 |1                                         |
                 |                                          |
                 v                                          v
       +-------------------+                     +--------------------+
       | RESEARCHER_TOPIC  |                     | PUBLICATION_TOPIC  |
       +-------------------+                     +--------------------+
       | PK,FK researcher_id|                    | PK,FK publicat_id  |
       | PK,FK topic_id    |0<-----------------+ | PK,FK topic_id     |
       |       interest_lvl|                   | +--------------------+
       +-------------------+                   |            |
                                               v            |
                                     +--------------------+ |
                                     |   RESEARCH_TOPIC   |0+
                                     +--------------------+
                                     | PK topic_id        |
                                     |    name (UQ)       |
                                     |    description     |
                                     +--------------------+
                                               ^
                                               |
                                     +--------------------+
                                     |  CONFERENCE_TOPIC  |
                                     +--------------------+
                                     | PK,FK conferenc_id |
                                     | PK,FK topic_id     |
                                     +--------------------+
                                               |0
                                               |
                                               v1
                                     +--------------------+
                                     |     CONFERENCE     |
                                     +--------------------+
                                     | PK conference_id   |
                                     |    name (UQ)       |
                                     |    deadline        |
                                     |    status          |
                                     +--------------------+
```

---

## 4. Relational Model & Schema Diagram

### List of Relations That Are Not Entities in the ER Model

The following relational tables represent junction tables created exclusively to decompose Many-to-Many ($M:N$) relationships into pairs of One-to-Many ($1:M$) relationships, or to establish self-referencing pairs:

1. **`authorship`**: Decomposes the $M:N$ relationship between `researcher` and `publication`.
2. **`collaboration`**: Decomposes the symmetric $M:N$ recursive partnership between `researcher` and `researcher`.
3. **`researcher_project`**: Decomposes the $M:N$ relationship between `researcher` and `project`.
4. **`researcher_topic`**: Decomposes the $M:N$ relationship between `researcher` and `research_topic`.
5. **`publication_topic`**: Decomposes the $M:N$ relationship between `publication` and `research_topic`.
6. **`conference_topic`**: Decomposes the $M:N$ relationship between `conference` and `research_topic`.

---

### Relational Schema Representation

*Primary keys are denoted with **bold** and `[PK]`, Foreign keys with `[FK]`.*

1. **admin** (
   **admin_id** `[PK]`, name, email `[UQ]`, password_hash, role, is_active, created_at
   )
2. **researcher** (
   **researcher_id** `[PK]`, name, email `[UQ]`, institution, bio, password_hash, is_active, created_at
   )
3. **publication** (
   **publication_id** `[PK]`, title, abstract, publication_date, doi `[UQ]`, url, embedding `(vector-768)`, created_at, updated_at
   )
4. **project** (
   **project_id** `[PK]`, name, description, start_date, end_date, budget, status, created_at
   )
5. **conference** (
   **conference_id** `[PK]`, name `[UQ]`, location, submission_deadline, start_date, end_date, website_url, status, created_at, updated_at
   )
6. **research_topic** (
   **topic_id** `[PK]`, name `[UQ]`, description, parent_topic_id `[FK -> research_topic.topic_id]`, created_at
   )
7. **authorship** (
   **publication_id** `[PK, FK -> publication]`, **researcher_id** `[PK, FK -> researcher]`, author_order, created_at
   )
8. **collaboration** (
   **collaboration_id** `[PK]`, researcher_id_1 `[FK -> researcher]`, researcher_id_2 `[FK -> researcher]`, similarity_score, created_at
   )
9. **researcher_project** (
   **researcher_id** `[PK, FK -> researcher]`, **project_id** `[PK, FK -> project]`, role, joined_at
   )
10. **researcher_topic** (
    **researcher_id** `[PK, FK -> researcher]`, **topic_id** `[PK, FK -> research_topic]`, interest_level, created_at
    )
11. **publication_topic** (
    **publication_id** `[PK, FK -> publication]`, **topic_id** `[PK, FK -> research_topic]`
    )
12. **conference_topic** (
    **conference_id** `[PK, FK -> conference]`, **topic_id** `[PK, FK -> research_topic]`
    )
13. **admin_audit_log** (
    **audit_id** `[PK]`, admin_id `[FK -> admin]`, target_table, target_id, action_type, old_values, new_values, performed_at
    )

---

## 5. SQL DDL Statements

The database structure is implemented using PostgreSQL 16 DDL with constraints including `PRIMARY KEY`, `FOREIGN KEY` with cascading, `UNIQUE`, `CHECK` regex formats, and custom indexes.

```sql
-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Entity: Admin
CREATE TABLE admin (
    admin_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'admin',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_admin_email UNIQUE (email),
    CONSTRAINT chk_admin_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_admin_role CHECK (role IN ('super_admin', 'admin', 'moderator'))
);

-- 3. Entity: Researcher (replaces reserved keyword USER)
CREATE TABLE researcher (
    researcher_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    institution VARCHAR(200),
    bio TEXT,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_researcher_email UNIQUE (email),
    CONSTRAINT chk_researcher_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 4. Entity: Publication with pgvector Support
CREATE TABLE publication (
    publication_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    abstract TEXT,
    publication_date DATE NOT NULL,
    doi VARCHAR(100),
    url VARCHAR(500),
    embedding vector(768),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_publication_doi UNIQUE (doi),
    CONSTRAINT chk_publication_date CHECK (publication_date <= CURRENT_DATE),
    CONSTRAINT chk_publication_doi_format CHECK (doi IS NULL OR doi ~* '^10\.\d{4,9}/[-._;()/:A-Za-z0-9]+$')
);

-- 5. Entity: Conference
CREATE TABLE conference (
    conference_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    location VARCHAR(200),
    submission_deadline DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    website_url VARCHAR(500),
    status VARCHAR(50) NOT NULL DEFAULT 'upcoming',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_conference_name UNIQUE (name),
    CONSTRAINT chk_conference_dates CHECK (start_date <= end_date),
    CONSTRAINT chk_submission_before_start CHECK (submission_deadline <= start_date),
    CONSTRAINT chk_conference_status CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled'))
);

-- 6. Entity: Research Topic (with Self-Referencing Hierarchy)
CREATE TABLE research_topic (
    topic_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    parent_topic_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_topic_name UNIQUE (name),
    CONSTRAINT fk_topic_parent FOREIGN KEY (parent_topic_id) 
        REFERENCES research_topic(topic_id) ON DELETE SET NULL
);

-- 7. Junction Table: Authorship (M:N)
CREATE TABLE authorship (
    publication_id BIGINT NOT NULL,
    researcher_id BIGINT NOT NULL,
    author_order INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (publication_id, researcher_id),
    CONSTRAINT fk_authorship_publication FOREIGN KEY (publication_id) 
        REFERENCES publication(publication_id) ON DELETE CASCADE,
    CONSTRAINT fk_authorship_researcher FOREIGN KEY (researcher_id) 
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT chk_author_order_positive CHECK (author_order > 0),
    CONSTRAINT uq_publication_author_order UNIQUE (publication_id, author_order)
);

-- 8. Junction Table: Collaboration (Self-Referencing M:N)
CREATE TABLE collaboration (
    collaboration_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    researcher_id_1 BIGINT NOT NULL,
    researcher_id_2 BIGINT NOT NULL,
    similarity_score NUMERIC(5, 4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_collab_researcher_1 FOREIGN KEY (researcher_id_1) 
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT fk_collab_researcher_2 FOREIGN KEY (researcher_id_2) 
        REFERENCES researcher(researcher_id) ON DELETE CASCADE,
    CONSTRAINT chk_no_self_collaboration CHECK (researcher_id_1 <> researcher_id_2),
    CONSTRAINT chk_canonical_order CHECK (researcher_id_1 < researcher_id_2),
    CONSTRAINT uq_collaboration_pair UNIQUE (researcher_id_1, researcher_id_2),
    CONSTRAINT chk_similarity_score_range CHECK (similarity_score IS NULL OR (similarity_score >= 0.0000 AND similarity_score <= 1.0000))
);

-- 9. HNSW Index for Fast Approximate Nearest Neighbor Vector Search
CREATE INDEX idx_publication_embedding_hnsw 
ON publication USING hnsw (embedding vector_cosine_ops);
```

---

## 6. SQL DML Statements & Advanced Operations

### Core DML Operations

#### 1. Inserting Publications and Topics

```sql
INSERT INTO publication (title, abstract, publication_date, doi, url)
VALUES (
    'Adaptive Indexing for High-Dimensional Vector Spaces',
    'Explores dynamic quantization and learned proximity graphs for sub-millisecond retrieval.',
    '2024-03-15',
    '10.1145/3617233.3617240',
    'https://doi.org/10.1145/3617233.3617240'
);

INSERT INTO research_topic (name, description)
VALUES ('Vector Databases & Search', 'Similarity indexing, HNSW, IVFFlat, and high-dimensional spaces');
```

#### 2. Establishing M:N Authorship Link

```sql
INSERT INTO authorship (publication_id, researcher_id, author_order)
VALUES (1, 1, 1), (1, 3, 2);
```

---

### Advanced SQL Query Demonstrations

#### Query A: Complex Multi-Table Inner Join with Grouping & Topic Concatenation

```sql
SELECT 
    p.publication_id,
    p.title,
    p.publication_date,
    p.doi,
    STRING_AGG(DISTINCT r.name, ', ' ORDER BY r.name) AS authors,
    COUNT(DISTINCT a.researcher_id) AS total_authors,
    STRING_AGG(DISTINCT t.name, '; ' ORDER BY t.name) AS topic_tags
FROM publication p
JOIN authorship a ON p.publication_id = a.publication_id
JOIN researcher r ON a.researcher_id = r.researcher_id
LEFT JOIN publication_topic pt ON p.publication_id = pt.publication_id
LEFT JOIN research_topic t ON pt.topic_id = t.topic_id
GROUP BY p.publication_id, p.title, p.publication_date, p.doi
ORDER BY p.publication_date DESC;
```

#### Query B: Correlated Subquery (Latest Paper per Researcher)

```sql
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    (
        SELECT p.title
        FROM authorship a
        JOIN publication p ON a.publication_id = p.publication_id
        WHERE a.researcher_id = r.researcher_id
        ORDER BY p.publication_date DESC, p.publication_id DESC
        LIMIT 1
    ) AS latest_publication
FROM researcher r
ORDER BY r.name ASC;
```

#### Query C: Common Table Expressions (CTE) for Institutional Research Output

```sql
WITH researcher_paper_counts AS (
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
    SELECT 
        institution,
        COUNT(researcher_id) AS total_scholars,
        SUM(paper_count) AS aggregate_papers,
        ROUND(AVG(paper_count), 2) AS average_papers_per_scholar
    FROM researcher_paper_counts
    WHERE institution IS NOT NULL
    GROUP BY institution
)
SELECT * FROM institution_metrics
ORDER BY aggregate_papers DESC;
```

#### Query D: Window Functions (DENSE_RANK and ROW_NUMBER)

```sql
SELECT 
    r.researcher_id,
    r.name,
    r.institution,
    COUNT(a.publication_id) AS total_papers,
    DENSE_RANK() OVER (ORDER BY COUNT(a.publication_id) DESC) AS productivity_rank,
    ROW_NUMBER() OVER (ORDER BY COUNT(a.publication_id) DESC, r.name ASC) AS rank_sequence
FROM researcher r
LEFT JOIN authorship a ON r.researcher_id = a.researcher_id
GROUP BY r.researcher_id, r.name, r.institution
ORDER BY productivity_rank ASC, rank_sequence ASC;
```

---

### Programmability: Functions, Procedures, and Triggers

#### 1. Function: Jaccard Similarity Calculator

```sql
CREATE OR REPLACE FUNCTION fn_calculate_topic_similarity(p_res1 BIGINT, p_res2 BIGINT)
RETURNS NUMERIC(5, 4)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_intersection_count INT;
    v_union_count INT;
BEGIN
    IF p_res1 = p_res2 THEN
        RETURN 1.0000;
    END IF;

    SELECT COUNT(*) INTO v_intersection_count
    FROM researcher_topic t1
    JOIN researcher_topic t2 ON t1.topic_id = t2.topic_id
    WHERE t1.researcher_id = p_res1 AND t2.researcher_id = p_res2;

    SELECT COUNT(DISTINCT topic_id) INTO v_union_count
    FROM researcher_topic
    WHERE researcher_id IN (p_res1, p_res2);

    IF v_union_count = 0 THEN
        RETURN 0.0000;
    END IF;

    RETURN ROUND((v_intersection_count::NUMERIC / v_union_count::NUMERIC), 4);
END;
$$;
```

#### 2. Trigger: Automatic Timestamp Maintenance

```sql
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_publication_updated_at
    BEFORE UPDATE ON publication
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();
```

---

## 7. NoSQL / Vector Database Commands

### A. Vector Database (PostgreSQL + pgvector)

#### 1. Extension Initialization & Table Alteration

```sql
CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE publication 
ADD COLUMN IF NOT EXISTS embedding vector(768);
```

#### 2. Creating HNSW Vector Index

```sql
CREATE INDEX IF NOT EXISTS idx_publication_embedding_hnsw 
ON publication USING hnsw (embedding vector_cosine_ops);
```

#### 3. Semantic Similarity Query via Cosine Distance (`<=>`)

```sql
-- Retrieve the top 5 most relevant papers matching an input vector embedding
SELECT 
    publication_id,
    title,
    doi,
    1 - (embedding <=> '[0.0124, -0.0512, 0.0931, ..., 0.0211]'::vector) AS cosine_similarity
FROM publication
WHERE embedding IS NOT NULL
ORDER BY embedding <=> '[0.0124, -0.0512, 0.0931, ..., 0.0211]'::vector ASC
LIMIT 5;
```

---

### B. NoSQL Database (MongoDB Commands via PyMongo)

#### 1. MongoDB Connection Setup

```python
from pymongo import MongoClient

mongo_client = MongoClient("mongodb://localhost:27017/")
mongo_db = mongo_client["research_intelligence"]
activity_collection = mongo_db["activity_logs"]
```

#### 2. Create / Insert Activity Document (C in CRUD)

```python
doc = {
    "action": "SEMANTIC_SEARCH",
    "user_id": 1,
    "user_email": "aris.thorne@cam.ac.uk",
    "role": "researcher",
    "details": {
        "query_text": "High-dimensional vector indexing",
        "returned_results_count": 5
    },
    "ip_address": "127.0.0.1",
    "timestamp": datetime.now(timezone.utc)
}
activity_collection.insert_one(doc)
```

#### 3. Read / Query Activity Logs with Filtering & Sorting (R in CRUD)

```python
# Equivalent to db.activity_logs.find({"role": "researcher"}).sort("timestamp", -1).limit(10)
results = list(activity_collection.find(
    {"role": "researcher"},
    {"_id": 0, "action": 1, "user_email": 1, "timestamp": 1, "details": 1}
).sort("timestamp", -1).limit(10))
```

#### 4. Update / Enrich Activity Document (U in CRUD)

```python
# Equivalent to db.activity_logs.update_one({"user_id": 1}, {"$set": {"status": "RESOLVED"}})
activity_collection.update_one(
    {"user_id": 1, "action": "LOGIN_ATTEMPT"},
    {"$set": {"status": "VERIFIED_2FA"}}
)
```

#### 5. Delete Activity Document (D in CRUD)

```python
# Purge test or expired audit logs older than 90 days
activity_collection.delete_many(
    {"timestamp": {"$lt": datetime(2025, 1, 1, tzinfo=timezone.utc)}}
)
```

---

## 8. Results & Resulting Tables' CLI Outputs

### 1. View: Publication Details with Aggregated Authors (`v_publication_details`)

```text
 publication_id |                        title                        |      authors                   | author_count |             topics
----------------+-----------------------------------------------------+--------------------------------+--------------+---------------------------------
              1 | Adaptive Indexing for High-Dimensional Vector Spaces| Dr. Aris Thorne, Dr. Rajan Patel|            2 | Vector Databases & Search
              2 | Federated Query Processing on Hybrid Cloud Engines  | Dr. Mei-Ling Zhou              |            1 | Distributed Query Processing
              3 | Learned Cost Models for Relational Query Optimizers | Dr. Aris Thorne, Dr. Marcus Vance|          2 | Query Optimization; AI Systems
```

### 2. View: Upcoming Conferences with Countdown (`v_upcoming_conferences`)

```text
 conference_id | conference_name |   location   | submission_deadline | days_until_deadline |           topic_tracks
---------------+-----------------+--------------+---------------------+---------------------+----------------------------------
             1 | VLDB 2026       | London, UK   | 2026-03-01          |                  72 | Distributed Query Processing
             2 | SIGMOD 2026     | Denver, USA  | 2026-04-15          |                 117 | Vector Databases & Search
             3 | ICDE 2026       | Helsinki, FI | 2026-05-10          |                 142 | Machine Learning Systems
```

### 3. View: Researcher Productivity Counts (`v_researcher_publication_counts`)

```text
 researcher_id |      name       |       institution       | total_publications | lead_author_publications
---------------+-----------------+-------------------------+--------------------+--------------------------
             1 | Dr. Aris Thorne | University of Cambridge |                  4 |                        3
             2 | Dr. Mei-Ling    | National Univ Singapore |                  3 |                        2
             3 | Dr. Rajan Patel | IIT Bombay              |                  2 |                        1
             4 | Dr. Marcus Vance| Stanford University     |                  2 |                        0
```

### 4. Automated Verification Test Suite (06_tests.sql)

```text
                        test_name                         | status |                         details
----------------------------------------------------------+--------+----------------------------------------------------------
 TC-01: Admin email uniqueness constraint                | PASS   | Duplicate email blocked successfully.
 TC-02: Researcher email regex constraint                 | PASS   | Invalid email format blocked.
 TC-03: Publication DOI uniqueness constraint             | PASS   | Duplicate DOI correctly rejected.
 TC-04: Conference start_date <= end_date constraint      | PASS   | Inverted conference date range blocked.
 TC-05: Conference submission_deadline <= start_date      | PASS   | Submission deadline after conference start blocked.
 TC-06: Authorship positive author_order constraint       | PASS   | Zero author order rejected.
 TC-07: Collaboration canonical order constraint          | PASS   | Inverted collaboration ID pair (id1 > id2) blocked.
 TC-08: Collaboration self-pair prevention constraint     | PASS   | Self-collaboration (id1 = id2) blocked.
 TC-09: Collaboration similarity_score range [0, 1]       | PASS   | Out-of-bounds similarity score (1.50) rejected.
 TC-10: Publication trg_publication_updated_at trigger    | PASS   | updated_at auto-advanced on row modification.
 TC-11: Conference fn_audit_conference_changes trigger    | PASS   | admin_audit_log populated on conference deadline update.
 TC-12: Stored Procedure sp_update_conference_status      | PASS   | Status transitioned from upcoming to ongoing with audit.
 TC-13: Stored Function fn_calculate_topic_similarity    | PASS   | Jaccard similarity returned expected positive numeric.
```

---

## 9. Project Tree Structure & Application Topology

The application is structured into decoupled frontend, backend, database scripts, and container orchestration layers:

```text
DBMS_Project/
├── .env                              # Environment configuration (Ports, DB URLs, Secrets)
├── .env.example                      # Template environment variables
├── .gitignore                        # Git ignore patterns
├── docker-compose.yml                # Multi-container orchestration (PostgreSQL 16 + Mongo 8)
├── package-lock.json                 # Top-level dependency tracking
├── PROJECT_FLOW_AND_FILE_GUIDE.md    # Complete architectural manual
├── README.md                         # Project documentation & runbook
├── requirements.txt                  # Python dependencies (FastAPI, PyMongo, Psycopg, PyTorch)
├── backend/                          # FastAPI RESTful Microservice
│   ├── generate_embeddings.py        # Offline neural embedding generator
│   ├── validate_embeddings.py        # Vector similarity test suite
│   └── app/
│       ├── main.py                   # Server entrypoint and CORS configuration
│       ├── api/
│       │   ├── deps.py               # Dependency injection (DB pools, JWT extraction)
│       │   └── v1/
│       │       └── endpoints/
│       │           ├── auth.py             # User login, registration & token issuance
│       │           ├── meta.py             # Public taxonomies & metadata
│       │           ├── publications.py     # Publication CRUD & vector similarity search
│       │           ├── recommendations.py  # Collaborator matchmaking algorithms
│       │           └── researchers.py      # Scholar profiles & publication histories
│       ├── core/
│       │   ├── config.py             # Pydantic BaseSettings
│       │   ├── database.py           # Psycopg 3 connection pool & Mongo client
│       │   └── security.py           # Password hashing (bcrypt) & JWT encoding
│       ├── schemas/
│       │   └── all_schemas.py        # Pydantic request & response validation schemas
│       └── services/
│           ├── activity_service.py   # Async MongoDB audit logging routines
│           └── embedding_service.py  # In-memory sentence-transformers inference
├── frontend/                         # Client User Interface (React / Vite)
│   ├── index.html                    # Single-page HTML template
│   ├── package.json                  # NPM dependencies (React 19, Lucide, Vite)
│   ├── vite.config.js                # Build tool configuration
│   └── src/
│       ├── App.jsx                   # Primary UI view with responsive state management
│       ├── main.jsx                  # React DOM rendering entrypoint
│       └── services/
│           └── api.js                # Axios / Fetch client targeting backend REST routes
├── scripts/                          # Automated Administrative Scripts
│   ├── connect_db.ps1                # Interactive psql session launcher
│   ├── run_all.ps1                   # Sequential SQL execution runner
│   └── run_tests.ps1                 # Automated test suite runner
└── sql/                              # Relational Database SQL Files
    ├── 01_schema.sql                 # Table DDL, keys, constraints & check rules
    ├── 02_sample_data.sql            # Normalized data seeding script
    ├── 03_queries.sql                # 16 Complex queries, joins, CTEs & window functions
    ├── 04_advanced_sql.sql           # Views, triggers, PL/pgSQL functions & procedures
    ├── 05_transactions.sql           # ACID transaction blocks & savepoint rollbacks
    ├── 06_tests.sql                  # 13 Automated verification test cases
    └── 07_add_vector_embedding.sql   # pgvector migration script
```

---

## 10. Application Code Snippets & Interface Integration

### Backend: Vector Similarity Search Endpoint (`backend/app/api/v1/endpoints/publications.py`)

```python
@router.post("/search/semantic", response_model=List[PublicationResponse])
def semantic_search_publications(
    payload: SemanticSearchRequest,
    db=Depends(get_db),
    current_user=Depends(get_current_user_optional)
):
    """Encodes search query into 768-dim vector and runs cosine nearest-neighbor search via pgvector."""
    query_vector = embed_text(payload.query)
    vector_literal = "[" + ",".join(str(x) for x in query_vector) + "]"

    query = """
        SELECT 
            p.publication_id, p.title, p.abstract, p.publication_date, p.doi, p.url,
            (1 - (p.embedding <=> %s::vector)) AS similarity_score
        FROM publication p
        WHERE p.embedding IS NOT NULL
        ORDER BY p.embedding <=> %s::vector ASC
        LIMIT %s;
    """
    with db.cursor() as cur:
        cur.execute(query, (vector_literal, vector_literal, payload.limit))
        rows = cur.fetchall()

    # Log query to MongoDB audit trail
    log_research_activity(
        action="SEMANTIC_SEARCH",
        user_id=current_user.get("id") if current_user else None,
        details={"query": payload.query, "count": len(rows)}
    )
    return rows
```

### Backend: Role-Based Access Control (`backend/app/core/security.py`)

```python
def verify_admin_role(current_user: dict = Depends(get_current_user)):
    """Enforces administrative privilege for protected endpoints."""
    if current_user.get("role") not in ["super_admin", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: Administrative privileges required."
        )
    return current_user
```

### Frontend: API Integration Client (`frontend/src/services/api.js`)

```javascript
const API_BASE = "http://localhost:8000/api/v1";

export async function semanticSearch(query, limit = 5) {
  const token = localStorage.getItem("token");
  const headers = { "Content-Type": "application/json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const response = await fetch(`${API_BASE}/publications/search/semantic`, {
    method: "POST",
    headers,
    body: JSON.stringify({ query, limit })
  });
  if (!response.ok) throw new Error("Semantic search query failed");
  return await response.json();
}
```

---

## 11. Evaluation Rubrics - Completion Status

|      #      | Criteria                                                   | Distribution                                                                                                 |       Status       | Detailed Implementation Evidence                                                                                                                                                                                                                             |
| :---------: | :--------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------- | :-----------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | **Database Design**                                  | ER diagram, relational schema with keys, relationships, and constraints                                      | **COMPLETED** | Complete ER diagram with entities, weak entities (`admin_audit_log`), M:N resolvers, composite/derived attributes, and 3NF relational schemas with strict PK/FK definitions.                                                                               |
| **2** | **Database Creation**                                | SQL database implementation - DDL with constraints, NoSQL/Vector database creation, Technology justification | **COMPLETED** | PostgreSQL 16 DDL (`01_schema.sql`) with regex email checks, date ordering checks, `pgvector` HNSW indexes (`07_add_vector_embedding.sql`), and MongoDB 8 document collection initialized via Docker.                                                  |
| **3** | **SQL Operations & Queries**                         | DML operations, Nested/correlated/Recursive SQL queries, Join SQL queries                                    | **COMPLETED** | Comprehensive script (`03_queries.sql`) containing 16 complex queries: multi-table inner/outer joins, relational division, uncorrelated/correlated subqueries, and window functions (`DENSE_RANK`).                                                      |
| **4** | **Advanced Database Concepts**                       | Advanced database concepts (Procedure/function, trigger, CTE), NoSQL/Vector feature CRUD                     | **COMPLETED** | Implemented Jaccard similarity function (`fn_calculate_topic_similarity`), status procedure (`sp_update_conference_status`), update triggers (`fn_set_updated_at`, `fn_audit_conference_changes`), recursive CTEs, and full PyMongo CRUD operations. |
| **5** | **Web Application & Database Integration**           | Next.js / React interface, Backend/API and database integration                                              | **COMPLETED** | High-performance FastAPI REST backend with Psycopg 3 connection pools and MongoDB connectors, interfaced with a reactive React 19 / Vite UI for real-time semantic discovery.                                                                                |
| **6** | **Authentication & Authorization**                   | Authentication implementation (frontend and backend) and minimum two roles with RBAC                         | **COMPLETED** | End-to-end JWT Bearer authentication implemented across backend endpoints with role separation between`super_admin`, `admin`, `moderator`, and `researcher`.                                                                                         |
| **7** | **Documentation, Git/GitHub, Testing & Originality** | Documentation, Git/GitHub, Originality and individual contribution                                           | **COMPLETED** | Automated 13-case SQL test suite (`06_tests.sql`), clean Git repository structure, comprehensive architecture guide (`PROJECT_FLOW_AND_FILE_GUIDE.md`), and modular scripts.                                                                             |

---

*Report compiled for Department of Computer Science & Engineering (AI & ML), PES University.*
