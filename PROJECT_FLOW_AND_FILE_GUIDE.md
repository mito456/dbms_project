# Research Collaboration & Publication Intelligence System

## Complete Architecture, File-by-File Technical Guide & Unified Execution Manual

---

### Executive Overview & System Topology

The **Research Collaboration & Publication Intelligence System** is an enterprise-grade academic networking and discovery platform. It merges relational database rigor (PostgreSQL 16), vector similarity search (`pgvector` with 768-dimensional BGE embeddings), document-based audit trail logging (MongoDB 8), a high-performance RESTful backend (FastAPI), and a reactive frontend (React 19 + Vite + Lucide).

```
                                  +-----------------------------+
                                  |     React 19 Frontend       |
                                  |  (Vite Dev Server :5173)    |
                                  +--------------+--------------+
                                                 |
                                     HTTP / REST (JSON API)
                                                 |
                                                 v
                                  +-----------------------------+
                                  |      FastAPI Backend        |
                                  |      (Uvicorn :8000)        |
                                  +-------+--------------+------+
                                          |              |
                       SQL / DictRow (psycopg 3)    BSON Logs (pymongo)
                                          |              |
                                          v              v
           +--------------------------------+   +-----------------------+
           |     PostgreSQL 16 + pgvector   |   |       MongoDB 8       |
           |     Docker Port: 5433 / 5432   |   |   Docker Port: 27017  |
           |  - Relational Schema (13 tabs) |   | - Non-blocking audits |
           |  - Cosine Embeddings (768-dim) |   | - User activity logs  |
           |  - Triggers, Views & Functions |   |                       |
           +--------------------------------+   +-----------------------+
```

---

## 1. End-to-End System Flow Across Lifecycle Stages

The system operates across **5 distinct chronological stages**:

```mermaid
flowchart TD
    subgraph Stage 1: Infrastructure & Storage Engine
        A1[docker-compose.yml] --> A2[PostgreSQL 16 Container with pgvector]
        A1 --> A3[MongoDB 8 Container for Activity Audits]
        A4[.env] --> A1
    end

    subgraph Stage 2: Database Schema, Programmability & Verification
        B1[01_schema.sql] -->|DDL, PK/FK, Constraints| B2[Tables Created]
        B3[02_sample_data.sql] -->|DML Seeding| B2
        B4[04_advanced_sql.sql] -->|Views, Triggers, Functions| B2
        B5[05_transactions.sql] -->|ACID Scenarios| B2
        B6[06_tests.sql] -->|13 Automated Checks| B2
    end

    subgraph Stage 3: AI Vectorization & Neural Indexing
        C1[generate_embeddings.py] -->|Load BAAI/bge-base-en-v1.5| C2[Encode Title + Abstract]
        C2 -->|768-dim vector| B2
        C3[validate_embeddings.py] -->|Verify Cosine Precision| B2
    end

    subgraph Stage 4: High-Performance Backend Service
        D1[main.py] --> D2[API Routers: Auth, Pubs, Recs, Researchers, Meta]
        D2 --> D3[embedding_service.py: In-memory Embedding Engine]
        D2 --> D4[activity_service.py: Async Mongo Audit Logging]
        D2 --> D5[database.py: Connection Pool & DictRow]
    end

    subgraph Stage 5: Reactive UI & Client Workflows
        E1[App.jsx] -->|Fetch Data & Bearer Auth| D1
        E2[Semantic Search UI]
        E3[Collaborator Match UI]
        E4[Conference Deadlines]
        E5[Researcher Profile & Publishing]
    end

    Stage 1 --> Stage 2 --> Stage 3 --> Stage 4 --> Stage 5
```

---

## 2. Comprehensive File-by-File Content Analysis

Every file in the repository is organized below by architectural stage in execution order.

### Stage 1: Environment & Container Orchestration

#### [`.env`](file:///c:/DBMS_Project/.env) & [`.env.example`](file:///c:/DBMS_Project/.env.example)

* **Purpose**: Centralized key-value configuration consumed by Docker, Python, and the shell.
* **Core Variables**:
  * `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`: PostgreSQL administrative credentials (`postgres`, `postgres`, `research_db`).
  * `POSTGRES_PORT=5433`: The host machine port bound to Docker's internal `5432` port (avoids port collisions if a native PostgreSQL is installed locally).
  * `DATABASE_URL=postgresql://postgres:postgres@localhost:5433/research_db`: Direct psycopg3/SQLAlchemy connection string.
  * `MONGO_URI=mongodb://localhost:27017/` & `MONGO_DB_NAME=research_intelligence`: MongoDB connection parameters.
  * `SECRET_KEY`, `ALGORITHM=HS256`, `ACCESS_TOKEN_EXPIRE_MINUTES=1440`: Cryptographic signing tokens for JWT authorization.
  * `EMBEDDING_MODEL_NAME=BAAI/bge-base-en-v1.5` & `EMBEDDING_DIM=768`: Neural model configuration.

#### [`docker-compose.yml`](file:///c:/DBMS_Project/docker-compose.yml)

* **Purpose**: Multi-container infrastructure definition ensuring automated provisioning of storage engines without manual setup.
* **Services**:
  1. `postgres`: Runs official image `pgvector/pgvector:pg16`. Binds host port `5433` to container `5432`. Mounts `postgres_data` persistent volume and binds `./sql` read-only for migrations. Includes automated `pg_isready` healthcheck.
  2. `mongodb`: Runs official image `mongo:8`. Binds port `27017` with persistent volume `mongodb_data` and automated ping healthcheck.

#### [`.gitignore`](file:///c:/DBMS_Project/.gitignore)

* **Purpose**: Excludes sensitive keys (`.env`), database data volumes (`postgres_data/`), JavaScript build artifacts (`node_modules/`, `dist/`), and Python virtual environments (`.venv/`, `venv/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`) from Git commits.

---

### Stage 2: Database Layer (`/sql`) & Migration Scripts (`/scripts`)

#### [`sql/01_schema.sql`](file:///c:/DBMS_Project/sql/01_schema.sql)

* **Purpose**: Complete Data Definition Language (DDL) creating 12 relational entities and 1 audit table.
* **Key Components**:
  * **Entities**: `admin`, `researcher`, `publication`, `project`, `conference`, `research_topic`.
  * **Junction Tables (M:N)**: `authorship`, `collaboration`, `researcher_project`, `researcher_topic`, `publication_topic`, `conference_topic`.
  * **Audit Ledger**: `admin_audit_log` with JSON payload snapshots.
  * **Integrity Constraints**:
    * `chk_collaboration_no_self`: Enforces `researcher_id_1 < researcher_id_2`, preventing self-collaboration and eliminating duplicate inverted pairs.
    * `uq_publication_doi`: Allows multiple `NULL` values while enforcing global uniqueness on non-null DOIs.
    * `chk_conf_dates`: Guarantees `end_date >= start_date` and `submission_deadline <= start_date`.
    * Email regex constraints on `admin` and `researcher`.

#### [`sql/02_sample_data.sql`](file:///c:/DBMS_Project/sql/02_sample_data.sql)

* **Purpose**: Idempotent Data Manipulation Language (DML) seed script populating realistic academic data.
* **Key Contents**:
  * 3 Administrator accounts (Super Admin, Admin, Moderator).
  * 10 Researcher profiles across Oxford, MIT, IISc Bangalore, ETH Zürich, ShanghaiTech, etc.
  * 10 Standardized Research Topics (`Distributed Consensus`, `Vector Databases & Search`, `Query Optimization`, etc.).
  * 10 Milestone Publications with complete abstracts and DOIs.
  * Cross-linked `authorship`, `collaboration` edges with similarity scores, and upcoming `conference` schedules (`VLDB 2026`, `SIGMOD 2026`, `ICDE 2026`).

#### [`sql/03_queries.sql`](file:///c:/DBMS_Project/sql/03_queries.sql)

* **Purpose**: Academic and operational query showcase demonstrating DBMS Level 3 proficiency.
* **Key Queries**:
  * Multi-table inner/outer joins for author citations.
  * Subqueries and aggregations calculating lead author ratios.
  * Common Table Expressions (CTEs) detecting multi-disciplinary papers.
  * Window Functions: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()` for publication rankings per topic, and `LAG()` / `LEAD()` analyzing timeline intervals between submissions.

#### [`sql/04_advanced_sql.sql`](file:///c:/DBMS_Project/sql/04_advanced_sql.sql)

* **Purpose**: Programmable server-side database objects optimizing query performance and maintaining integrity.
* **Key Objects**:
  * **Views**:
    * `v_publication_details`: Merges publication data with comma-separated author lists (`STRING_AGG`) and semicolon-separated topics.
    * `v_researcher_publication_counts`: Summarizes career publications and lead authorship count.
    * `v_upcoming_conferences`: Live countdown of days remaining until submission deadlines.
    * `v_collaborations_bidirectional`: Symmetrically flattens `(id1, id2)` into both directions so queries can search any `researcher_id`.
  * **Triggers**:
    * `trg_publication_updated_at` & `trg_conference_updated_at`: Automatically updates timestamps on modification.
    * `trg_audit_conference_changes`: Automatically writes changes to `admin_audit_log` with before/after status.
  * **Functions & Stored Procedures**:
    * `fn_get_researcher_pub_count(p_id)`: Evaluates publication volume with boundary checks.
    * `fn_calculate_topic_similarity(r1, r2)`: Calculates Jaccard similarity coefficient:
      $$
      \text{Jaccard}(A, B) = \frac{|A \cap B|}{|A \cup B|}
      $$
    * `sp_update_conference_status(...)`: Transactional procedure with state validation and administrative audit logging.
  * **Indexes**: B-tree indexes on foreign keys, lower-cased email lookups, and conference deadlines.

#### [`sql/05_transactions.sql`](file:///c:/DBMS_Project/sql/05_transactions.sql)

* **Purpose**: Rigorous validation of ACID properties in PostgreSQL.
* **Scenarios**:
  * Scenario 1: Multi-table atomic insertion (`publication` + `authorship` + `publication_topic`) wrapped in `BEGIN ... COMMIT`.
  * Scenario 2: Rollback on constraint failure verifying database state remains unchanged.
  * Scenario 3: `SAVEPOINT` usage demonstrating partial rollbacks in multi-stage updates.

#### [`sql/06_tests.sql`](file:///c:/DBMS_Project/sql/06_tests.sql)

* **Purpose**: Automated test suite executing 13 test cases using PL/pgSQL anonymous `DO` blocks.
* **Coverage**: Verifies table existence, primary/foreign key enforcement, email format validations, non-self collaboration checks, trigger execution, and function accuracy.

#### [`scripts/run_all.ps1`](file:///c:/DBMS_Project/scripts/run_all.ps1)

* **Purpose**: PowerShell orchestration script that connects to the `research_intelligence_db` Docker container and sequentially applies `01_schema.sql`, `02_sample_data.sql`, and `04_advanced_sql.sql`.

#### [`scripts/run_tests.ps1`](file:///c:/DBMS_Project/scripts/run_tests.ps1)

* **Purpose**: Executes `06_tests.sql` inside the Docker container and outputs pass/fail status for all 13 test suites.

#### [`scripts/connect_db.ps1`](file:///c:/DBMS_Project/scripts/connect_db.ps1)

* **Purpose**: Spawns an interactive `psql` shell inside the running container with pager disabled (`PAGER=cat`) for direct console output.

---

### Stage 3: Vector Embeddings & Semantic Intelligence

#### [`backend/generate_embeddings.py`](file:///c:/DBMS_Project/backend/generate_embeddings.py)

* **Purpose**: Standalone data pipeline script for initial population of high-dimensional embeddings.
* **Functionality**:
  1. Connects to PostgreSQL via `.env` credentials with connection fallback.
  2. Loads the `BAAI/bge-base-en-v1.5` SentenceTransformer model.
  3. Iterates over all publications lacking an embedding, synthesizes `Title: <title>. Abstract: <abstract>`, generates a normalized 768-dimensional float vector, and updates `publication.embedding` using `::vector`.

#### [`backend/validate_embeddings.py`](file:///c:/DBMS_Project/backend/validate_embeddings.py)

* **Purpose**: Quality assurance script verifying vector integrity.
* **Functionality**: Re-encodes text using the neural model, computes cosine similarity between in-memory vectors and database vectors using NumPy dot products, and automatically repairs any drifting or missing embeddings.

---

### Stage 4: Backend Application Architecture (`/backend/app`)

#### [`backend/app/main.py`](file:///c:/DBMS_Project/backend/app/main.py)

* **Purpose**: Application entry point initializing FastAPI, configuring CORS middleware for the React frontend, and mounting routers under `/api/v1`.
* **Endpoints exposed**:
  * `/health`: System liveness check.
  * `/api/v1/auth`: Authentication and registration.
  * `/api/v1/publications`: Publication catalog and semantic search.
  * `/api/v1/researchers`: Profiles and topic associations.
  * `/api/v1/recommendations`: Collaborator and conference match algorithms.
  * `/api/v1/meta`: Taxonomy, conference deadlines, and system statistics.
  * `/api/v1/docs` & `/api/v1/redoc`: Interactive Swagger UI and ReDoc documentation.

#### [`backend/app/core/config.py`](file:///c:/DBMS_Project/backend/app/core/config.py)

* **Purpose**: Pydantic `BaseSettings` object dynamically resolving configuration from the root `.env` file. Provides typed attributes for database ports, hostnames, JWT keys, and model parameters.

#### [`backend/app/core/database.py`](file:///c:/DBMS_Project/backend/app/core/database.py)

* **Purpose**: Database session and client lifecycle management.
* **Functions**:
  * `get_db_connection()`: Generator dependency yielding a `psycopg.connect` instance with `dict_row` row factory, ensuring safe closing upon request completion.
  * `get_mongo_client()` / `get_mongo_db()`: Singleton MongoDB client with connection timeout handling.

#### [`backend/app/core/security.py`](file:///c:/DBMS_Project/backend/app/core/security.py)

* **Purpose**: Cryptographic security layer handling password hashing and JWT issuance.
* **Functions**:
  * `hash_password(pwd)`: Generates salt and hashes passwords using `bcrypt` (12 rounds).
  * `verify_password(plain, hashed)`: Constant-time verification supporting both active bcrypt hashes and backward-compatible seeded hashes.
  * `create_access_token(sub, role, expires_delta)`: Signs HS256 JWT tokens with role claims and expiration timestamps.

#### [`backend/app/api/deps.py`](file:///c:/DBMS_Project/backend/app/api/deps.py)

* **Purpose**: FastAPI dependency injection providing route security and role-based access control.
* **Dependencies**:
  * `oauth2_scheme`: Extracts Bearer tokens from the `Authorization` header.
  * `get_current_user(...)`: Decodes JWT, validates claims, fetches the live user profile from PostgreSQL (checking `is_active = TRUE`), and attaches authorization context.
  * `require_admin(...)`: Enforces administrative permissions, rejecting unauthorized requests with HTTP 403 Forbidden.

#### [`backend/app/schemas/all_schemas.py`](file:///c:/DBMS_Project/backend/app/schemas/all_schemas.py)

* **Purpose**: Pydantic request and response models enforcing contract validation and OpenAPI documentation.
* **Schema Groups**:
  * Auth: `Token`, `LoginRequest`, `ResearcherRegisterRequest`.
  * Researcher: `ResearcherProfile`, `ResearcherUpdate`, `ResearcherTopicOut`.
  * Publication: `PublicationOut`, `PublicationCreate`, `SemanticSearchQuery`, `SemanticSearchResult`.
  * Recommendations: `CollaboratorRecommendation`, `ConferenceRecommendation`.

#### [`backend/app/services/embedding_service.py`](file:///c:/DBMS_Project/backend/app/services/embedding_service.py)

* **Purpose**: Thread-safe Singleton service loading the `BAAI/bge-base-en-v1.5` SentenceTransformer model into memory once during application lifecycle. Exposes `encode_text()` and `encode_texts()` returning normalized float lists.

#### [`backend/app/services/activity_service.py`](file:///c:/DBMS_Project/backend/app/services/activity_service.py)

* **Purpose**: High-throughput non-relational logging service writing user activities directly to MongoDB's `activity_logs` collection. Converts non-serializable objects (such as `Decimal`) and retrieves recent activity feeds.

#### [`backend/app/api/v1/endpoints/auth.py`](file:///c:/DBMS_Project/backend/app/api/v1/endpoints/auth.py)

* **Purpose**: Handles authentication flows:
  * `POST /login`: Validates credentials across both `admin` and `researcher` tables; issues JWT Bearer tokens.
  * `POST /register`: Registers new researcher accounts with hashed passwords and optional initial topic interests.

#### [`backend/app/api/v1/endpoints/publications.py`](file:///c:/DBMS_Project/backend/app/api/v1/endpoints/publications.py)

* **Purpose**: CRUD operations for publications and pgvector semantic search:
  * `GET /`: Lists publications with optional topic filtering.
  * `POST /`: Inserts new publications, calculates BGE embedding, creates junction table links in `authorship` and `publication_topic`, and commits atomically.
  * `POST /search/semantic`: Converts user query into an embedding on the fly and runs a pgvector cosine similarity search:
    ```sql
    SELECT publication_id, title, abstract, (1 - (embedding <=> %s::vector)) AS similarity_score
    FROM publication
    WHERE embedding IS NOT NULL
    ORDER BY embedding <=> %s::vector ASC
    LIMIT %s;
    ```

#### [`backend/app/api/v1/endpoints/recommendations.py`](file:///c:/DBMS_Project/backend/app/api/v1/endpoints/recommendations.py)

* **Purpose**: Intelligent matching algorithms:
  * `GET /collaborators`: Computes a hybrid score combining Jaccard topic similarity (from SQL function `fn_calculate_topic_similarity`), shared co-authorship history, and vector similarity of authored publications.
  * `GET /conferences`: Matches researcher topics against upcoming conference tracks and evaluates deadline urgency.

#### [`backend/app/api/v1/endpoints/researchers.py`](file:///c:/DBMS_Project/backend/app/api/v1/endpoints/researchers.py)

* **Purpose**: Researcher profile lookups, publication attribution lists, and profile updates (bio, institution, topics).

#### [`backend/app/api/v1/endpoints/meta.py`](file:///c:/DBMS_Project/backend/app/api/v1/endpoints/meta.py)

* **Purpose**: Platform metadata endpoints returning taxonomy topics, upcoming conferences with days remaining, global counts (papers, researchers, topics), and recent MongoDB activity logs.

#### [`backend/tests/test_backend.py`](file:///c:/DBMS_Project/backend/tests/test_backend.py)

* **Purpose**: Automated API test suite using `pytest` and `fastapi.testclient.TestClient`. Tests health check, publication listing, semantic vector search, authentication, and collaborator recommendation endpoints.

---

### Stage 5: Frontend Application Architecture (`/frontend`)

#### [`frontend/package.json`](file:///c:/DBMS_Project/frontend/package.json)

* **Purpose**: Declares frontend dependencies: React 19, ReactDOM 19, Lucide React (vector icon suite), and Vite (bundler and dev server).

#### [`frontend/vite.config.js`](file:///c:/DBMS_Project/frontend/vite.config.js)

* **Purpose**: Configures Vite with the `@vitejs/plugin-react` plugin.

#### [`frontend/src/services/api.js`](file:///c:/DBMS_Project/frontend/src/services/api.js)

* **Purpose**: Centralized HTTP client wrapper. Automatically attaches JWT tokens from `localStorage` (`openscholar_token`) to outgoing requests and handles error responses.

#### [`frontend/src/App.jsx`](file:///c:/DBMS_Project/frontend/src/App.jsx)

* **Purpose**: Single-page application implementing the complete user experience:
  * Navigation header with active tab switching and live system metrics counters.
  * **Semantic Search Tab**: Natural language query input, topic dropdown, similarity threshold slider, and ranked result cards.
  * **Collaborator Matching Tab**: AI recommendation cards showing match scores and shared interest tags.
  * **Conference Radar Tab**: Submission deadline countdown badges and location tracking.
  * **Publications Tab**: Searchable paper catalog with author attributions.
  * **Researcher Profile Tab**: View profile, edit biography/institution, and manage research topics.
  * **Publish Paper Modal**: Modal dialog for creating publications, linking authors, and triggering backend vectorization.
  * **Authentication Modal**: Login and registration dialogs.
  * **Audit Log Drawer**: Live MongoDB activity feed.

#### [`frontend/src/index.css`](file:///c:/DBMS_Project/frontend/src/index.css) & [`frontend/src/App.css`](file:///c:/DBMS_Project/frontend/src/App.css)

* **Purpose**: Design system styling implementing a modern dark slate color palette, CSS grid layouts, smooth transitions, glassmorphic badges, and responsive design tokens.

---

## 3. Unified Global Environment Configuration

Previously, virtual environment dependencies were isolated under `./backend/.venv`. To streamline project execution, a **unified root environment** (`.venv`) is configured at the project root (`c:\DBMS_Project\.venv`).

### Unified Dependencies File: [`requirements.txt`](file:///c:/DBMS_Project/requirements.txt)

The root `requirements.txt` bundles all dependencies needed across the entire stack:

```text
fastapi==0.162.0
uvicorn==0.54.0
psycopg[binary]==3.3.6
pymongo==4.19.0
pydantic==2.14.1
pydantic-settings==2.16.1
sentence-transformers==6.2.0
torch==2.14.1
numpy==2.5.4
bcrypt==5.0.0
python-jose==3.5.0
python-dotenv==1.2.4
pytest==9.1.1
pytest-asyncio==1.4.1
httpx==0.28.1
```

---

## 4. Complete Execution & Operational Guide

Follow these steps to run the complete system from scratch.

### Step 1: Clone & Configure Environment

```powershell
# Navigate to project directory
cd c:\DBMS_Project

# Ensure .env is present (configured for Docker port 5433)
if (!(Test-Path .env)) { Copy-Item .env.example .env }
```

### Step 2: Activate the Global Python Environment

```powershell
# Activate the root unified virtual environment
.\.venv\Scripts\Activate.ps1

# (Optional: install/update all dependencies if cloning onto a new machine)
pip install -r requirements.txt
```

### Step 3: Launch Database Infrastructure (Docker)

```powershell
# Start PostgreSQL (with pgvector) and MongoDB containers in background
docker compose up -d

# Verify both containers are running and healthy
docker compose ps
```

### Step 4: Run Database Migrations & Verification

```powershell
# 1. Initialize schema, seed sample data, and create views/procedures
.\scripts\run_all.ps1

# 2. Run the automated database test suite (13 tests)
.\scripts\run_tests.ps1
```

### Step 5: Generate & Verify Vector Embeddings

```powershell
# Generate 768-dim BGE embeddings for all publications
python backend/generate_embeddings.py

# Validate embedding consistency with cosine precision checks
python backend/validate_embeddings.py
```

### Step 6: Start the FastAPI Backend Server

```powershell
# Set Python path to backend and start Uvicorn
$env:PYTHONPATH="c:\DBMS_Project\backend"
python -m uvicorn app.main:app --host 0.0.0.1 --port 8000 --reload
```

* **API Documentation**: Open your browser to [http://localhost:8000/api/v1/docs](http://localhost:8000/api/v1/docs)

### Step 7: Launch the React Frontend

Open a new terminal window:

```powershell
cd c:\DBMS_Project\frontend

# Install Node modules (if not already installed)
npm install

# Start Vite dev server
npm run dev
```

* **Web UI**: Open your browser to [http://localhost:5173](http://localhost:5173)

---

## 5. Default User Accounts for Testing

| Role                  | Name              | Email                            | Password     |
| :-------------------- | :---------------- | :------------------------------- | :----------- |
| **Researcher**  | Dr. Mei-Ling Zhou | `ml.zhou@shanghai-tech.edu`    | `password` |
| **Researcher**  | Dr. Aris Thorne   | `aris.thorne@oxford-cyber.edu` | `password` |
| **Researcher**  | Dr. Rajan Patel   | `r.patel@iisc-bangalore.ac.in` | `password` |
| **Super Admin** | Dr. Eleanor Vance | `e.vance@system.admin.org`     | `password` |
| **Moderator**   | Siddharth Menon   | `s.menon@system.admin.org`     | `password` |
