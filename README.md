# Research Collaboration & Publication Intelligence System
**DBMS Level 3 Project — Database & SQL Implementation**

A robust, relational database architecture implemented in PostgreSQL, designed to power an intelligent academic network for discovering research literature, tracking conference deadlines, and matching potential research collaborators.

---

## 1. Project Architecture & File Hierarchy

```text
DBMS_Project/
├── .env.example                 # Template environment variables
├── .env                         # Active local configuration (PostgreSQL port & credentials)
├── .gitignore                   # Ignores sensitive keys, docker volumes, and build caches
├── docker-compose.yml           # Pre-configured PostgreSQL 16 + pgvector container
├── README.md                    # Project documentation & execution guide
├── sql/                         # Modular database scripts (run in numerical order)
│   ├── 01_schema.sql            # Table DDL, primary/foreign keys, and constraints
│   ├── 02_sample_data.sql       # Realistic sample data & basic DML demonstrations
│   ├── 03_queries.sql           # Basic & complex queries, CTEs, and window functions
│   ├── 04_advanced_sql.sql      # Views, triggers, functions, procedures, and indexes
│   ├── 05_transactions.sql      # ACID transactions, rollbacks, and savepoints
│   └── 06_tests.sql             # Automated verification test suite (13 test cases)
└── scripts/                     # Automated helper scripts
    ├── run_all.ps1              # Runs schema, data, and advanced SQL into Docker
    ├── run_tests.ps1            # Runs automated test suite (06_tests.sql)
    └── connect_db.ps1           # Opens interactive psql terminal inside Docker container
```

---

## 2. Prerequisites & Quick Start

### Option A: Using Docker (Recommended — Pre-packages `pgvector`)

1. **Start the Database Container:**
   Make sure Docker Desktop is running, then open PowerShell in the project directory and run:
   ```powershell
   docker compose up -d
   ```
   *This starts PostgreSQL 16 with `pgvector` pre-installed and listening on `localhost:5432`.*

2. **Initialize Database & Seed Data:**
   Run the automated PowerShell helper:
   ```powershell
   .\scripts\run_all.ps1
   ```
   *This executes `01_schema.sql`, `02_sample_data.sql`, and `04_advanced_sql.sql` in sequence.*

3. **Run the Verification Suite:**
   ```powershell
   .\scripts\run_tests.ps1
   ```

4. **Connect via Interactive Terminal:**
   ```powershell
   .\scripts\connect_db.ps1
   ```

---

### Option B: Using Local PostgreSQL (psql / pgAdmin)

If you have PostgreSQL installed natively on your machine:

1. **Create the Database:**
   ```sql
   CREATE DATABASE research_db;
   \c research_db;
   ```
2. **Execute Scripts in Strict Numerical Order:**
   ```bash
   psql -U postgres -d research_db -f sql/01_schema.sql
   psql -U postgres -d research_db -f sql/02_sample_data.sql
   psql -U postgres -d research_db -f sql/03_queries.sql
   psql -U postgres -d research_db -f sql/04_advanced_sql.sql
   psql -U postgres -d research_db -f sql/05_transactions.sql
   psql -U postgres -d research_db -f sql/06_tests.sql
   ```

---

## 3. Database Schema & Relational Design

The system models **12 core entities** and 1 supplemental audit table:

| Entity | Type | Description |
| :--- | :--- | :--- |
| **`admin`** | Primary | System administrators with roles (`super_admin`, `admin`, `moderator`). |
| **`researcher`** | Primary | Academic users and researchers (replaces reserved keyword `USER`). |
| **`publication`** | Primary | Research papers, DOIs, abstracts, and publication dates. |
| **`project`** | Primary | Collaborative research initiatives and grants. |
| **`conference`** | Primary | Academic conferences with submission deadlines and dates. |
| **`research_topic`** | Primary | Standardized taxonomy of research domains and topics. |
| **`authorship`** | Junction (M:N) | Connects `researcher` and `publication` with explicit `author_order`. |
| **`collaboration`** | Junction (M:N) | Undirected collaboration ties with normalized similarity scores. |
| **`researcher_project`** | Junction (M:N) | Maps researchers to projects with defined roles. |
| **`researcher_topic`** | Junction (M:N) | Maps researchers to topics with validated `interest_level`. |
| **`publication_topic`** | Junction (M:N) | Maps publications to topical categories. |
| **`conference_topic`** | Junction (M:N) | Maps conferences to topical tracks. |
| **`admin_audit_log`** | Supplemental | Immutable audit ledger tracking changes made by administrators. |

### Key Integrity Constraints Explained

1. **Undirected Collaboration Guarantee:**
   ```sql
   CONSTRAINT chk_collaboration_no_self CHECK (researcher_id_1 < researcher_id_2),
   CONSTRAINT uq_collaboration_pair UNIQUE (researcher_id_1, researcher_id_2)
   ```
   * **No Self-Collaboration:** Enforces $id_1 < id_2$, so $id_1 = id_2$ is immediately rejected.
   * **No Duplicate Symmetric Pairs:** A pair $\{3, 7\}$ can only be inserted as $(3, 7)$. An attempt to insert $(7, 3)$ fails the check constraint, and inserting $(3, 7)$ again violates the uniqueness constraint.
   * *Bidirectional Querying:* View `v_collaborations_bidirectional` allows the web frontend to query either user as `researcher_id` symmetrically.

2. **Nullable Unique DOI:**
   * `CONSTRAINT uq_publication_doi UNIQUE (doi)` allows multiple draft/unpublished papers with `NULL` DOIs while strictly enforcing uniqueness whenever a non-null DOI is supplied.

3. **Temporal Validity Constraints:**
   * Conference dates: `CHECK (end_date >= start_date)` and `CHECK (submission_deadline <= start_date)`.
   * Project dates: `CHECK (end_date IS NULL OR end_date >= start_date)`.

---

## 4. Advanced Programmable Database Objects

### Dynamic Views
* `v_publication_details`: Consolidates publication records with aggregated author citations (`STRING_AGG`) and topics.
* `v_researcher_publication_counts`: Researcher productivity summary and lead-author count.
* `v_upcoming_conferences`: Conferences with live deadline countdowns (`(submission_deadline - CURRENT_DATE)`).
* `v_collaborations_bidirectional`: Flattens undirected pairs for effortless frontend integration.

### Triggers
* `trg_publication_updated_at` & `trg_conference_updated_at`: `BEFORE UPDATE` triggers automatically keeping `updated_at` current.
* `trg_audit_conference_changes`: `AFTER UPDATE` trigger automatically archiving status changes and JSON snapshots to `admin_audit_log`.

### Stored Functions & Procedures
* **Function `fn_get_researcher_pub_count(p_researcher_id)`:** Returns total publication count with verification.
* **Function `fn_calculate_topic_similarity(res1, res2)`:** Dynamically calculates Jaccard topic similarity $|A \cap B| / |A \cup B|$ between two researchers.
* **Procedure `sp_update_conference_status(conf_id, status, admin_id)`:** Validates and applies conference status updates with explicit administrative audit logging.

---

## 5. Security & Authentication Architecture

1. **Password Hashing:**
   * Passwords in `admin` and `researcher` are stored as `password_hash` (`VARCHAR(255)`).
   * **Rule:** Plaintext passwords must **never** touch the database. The Next.js / Node.js backend must hash passwords using `argon2id` or `bcrypt` prior to database persistence.
2. **Server-Side Authorization:**
   * Administrative procedures and routes must verify JSON Web Tokens (JWT) or session cookies on the backend server. The database never trusts client-supplied `admin_id` without server-tier validation.
3. **Environment Security:**
   * Production credentials belong strictly in `.env`, excluded from version control via `.gitignore`.

---

## 6. Forward Compatibility with `pgvector`

When extending this project into semantic search and AI recommendations:
1. **Activating Extension:**
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
   *(Already pre-compiled in our `docker-compose.yml` container image).*
2. **Adding Vector Columns:**
   ```sql
   ALTER TABLE publication ADD COLUMN embedding vector(1536);
   ALTER TABLE researcher ADD COLUMN interest_embedding vector(1536);
   ```
3. **Indexing for High-Dimensional Search:**
   ```sql
   CREATE INDEX idx_publication_embedding 
   ON publication USING hnsw (embedding vector_cosine_ops);
   ```
   *Enables lightning-fast cosine similarity queries (`<=>`) directly within SQL.*
