-- ============================================================================
-- Research Collaboration & Publication Intelligence System
-- File: 02_sample_data.sql
-- Description: Inserts realistic fictional data for testing & demonstrations.
-- Includes DML examples for INSERT, SELECT, UPDATE, and DELETE.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Reset Table Data (Idempotent seed run)
-- ----------------------------------------------------------------------------
TRUNCATE TABLE 
    admin_audit_log,
    conference_topic,
    publication_topic,
    researcher_topic,
    researcher_project,
    collaboration,
    authorship,
    research_topic,
    conference,
    project,
    publication,
    researcher,
    admin
RESTART IDENTITY CASCADE;

-- ============================================================================
-- 1. INSERT ADMINISTRATORS (3 Records)
-- ============================================================================
-- Note: password_hash values represent simulated bcrypt/Argon2 hashes.
INSERT INTO admin (name, email, password_hash, role, is_active)
VALUES
    ('Dr. Eleanor Vance', 'e.vance@system.admin.org', '$2b$12$e8Jk20qN9XwQJ0...simulatedHash1', 'super_admin', TRUE),
    ('Marcus Aurelius Brody', 'm.brody@system.admin.org', '$2b$12$m9Lk31rO0YxRK1...simulatedHash2', 'admin', TRUE),
    ('Siddharth Menon', 's.menon@system.admin.org', '$2b$12$s1Nm42sP1ZySL2...simulatedHash3', 'moderator', TRUE);

-- ============================================================================
-- 2. INSERT RESEARCHERS (10 Records)
-- ============================================================================
INSERT INTO researcher (name, email, institution, bio, password_hash, is_active)
VALUES
    ('Dr. Aris Thorne', 'aris.thorne@oxford-cyber.edu', 'Oxford Institute of Computing', 'Professor of Cryptography & Distributed Security with 15 years in fault-tolerant systems.', '$2b$12$hash_thorne_pwd', TRUE),
    ('Dr. Mei-Ling Zhou', 'ml.zhou@shanghai-tech.edu', 'Institute of Advanced Algorithms', 'Principal Scientist specializing in Graph Neural Networks and vector embeddings for NLP.', '$2b$12$hash_zhou_pwd', TRUE),
    ('Dr. Rajan Patel', 'r.patel@iisc-bangalore.ac.in', 'Indian Institute of Science', 'Associate Professor researching Query Optimization and Adaptive Distributed Storage Engines.', '$2b$12$hash_patel_pwd', TRUE),
    ('Dr. Clara Oswald', 'c.oswald@mit-csail.edu', 'MIT CSAIL', 'Assistant Professor working on Autonomous Agentic Planning, RAG systems, and LLM reasoning.', '$2b$12$hash_oswald_pwd', TRUE),
    ('Dr. Jean-Luc Picard', 'jl.picard@polytechnique.fr', 'École Polytechnique', 'Senior Research Fellow in Computational Genomics, biological sequence search, and high-throughput pipelines.', '$2b$12$hash_picard_pwd', TRUE),
    ('Dr. Sofia Al-Mansoor', 's.almansoor@kaust.edu.sa', 'KAUST Core Computing Labs', 'Lead Researcher in Quantum Cryptography, Post-Quantum Lattice Key Exchange, and privacy preserving DBs.', '$2b$12$hash_mansoor_pwd', TRUE),
    ('Dr. Liam O’Connor', 'l.oconnor@trinity-dublin.ie', 'Trinity College Dublin', 'Lecturer in Database Internals, transactional concurrency models, and consensus algorithms.', '$2b$12$hash_oconnor_pwd', TRUE),
    ('Dr. Elena Rostova', 'e.rostova@ethz.ch', 'ETH Zürich', 'Postdoctoral Fellow exploring Multi-Modal Vector Databases, HNSW indexing, and GPU-accelerated joins.', '$2b$12$hash_rostova_pwd', TRUE),
    ('Dr. Kenji Sato', 'k.sato@kyoto-u.ac.jp', 'Kyoto Center for Informatics', 'Specialist in Knowledge Graphs, semantic entity resolution, and automated ontology extraction.', '$2b$12$hash_sato_pwd', TRUE),
    ('Dr. Amara Okafor', 'a.okafor@uct.ac.za', 'University of Cape Town', 'Researcher in Edge AI, localized federated learning, and resource-constrained distributed ML.', '$2b$12$hash_okafor_pwd', TRUE);

-- ============================================================================
-- 3. INSERT RESEARCH TOPICS (10 Topics)
-- ============================================================================
INSERT INTO research_topic (name, description, category)
VALUES
    ('Distributed Consensus', 'Raft, Paxos, and Byzantine Fault Tolerant distributed state machine replication.', 'Systems'),
    ('Vector Databases & Search', 'High-dimensional vector indexing, HNSW, IVF, and similarity search for embedding models.', 'Databases'),
    ('Query Optimization', 'Cost-based query evaluation, adaptive join algorithms, and cardinality estimation.', 'Databases'),
    ('Graph Neural Networks', 'Deep learning on topological graphs, message passing neural networks, and link prediction.', 'Artificial Intelligence'),
    ('Post-Quantum Cryptography', 'Lattice-based, code-based, and isogeny cryptography resistant to Shor’s algorithm.', 'Cybersecurity'),
    ('Retrieval-Augmented Generation', 'Architectures augmenting generative language models with external vector and relational search.', 'Artificial Intelligence'),
    ('Computational Genomics', 'Algorithms for sequence alignment, genome assembly, and structural variant discovery.', 'Bioinformatics'),
    ('Database Transaction Concurrency', 'Multi-Version Concurrency Control (MVCC), serializability, and lock-free data structures.', 'Databases'),
    ('Privacy-Preserving Computation', 'Differential privacy, zero-knowledge proofs, and secure multi-party computation.', 'Cybersecurity'),
    ('Federated Learning', 'Decentralized collaborative machine learning without centralizing raw participant data.', 'Artificial Intelligence');

-- ============================================================================
-- 4. INSERT PUBLICATIONS (12 Records)
-- ============================================================================
INSERT INTO publication (title, abstract, publication_date, url, doi)
VALUES
    ('Adaptive Indexing for High-Dimensional Vector Spaces', 'We introduce an adaptive partition tree structure that dynamically balances query latency and recall in metric vector search engines.', '2024-03-15', 'https://openres.org/papers/2024/vector-indexing', '10.1016/j.datakb.2024.10101'),
    ('Byzantine Consensus Under Asymmetric Network Partitions', 'A formalized proof and protocol achieving quorum consensus under adversarial network delays without compromising liveness.', '2023-11-20', 'https://openres.org/papers/2023/byzantine-partitions', '10.1145/3600000.3600102'),
    ('Graph-Guided Knowledge Extraction in Biomedical Literature', 'Using link prediction and GNNs across 5 million PubMed articles to discover unrecorded gene-disease interactions.', '2024-05-10', 'https://openres.org/papers/2024/gnn-biomedical', '10.1093/bioinformatics/btae204'),
    ('Scalable Multi-Version Concurrency Control for Cloud-Native Relational Engines', 'This paper analyzes commit ordering and latch-free timestamp allocation for distributed multi-tenant PostgreSQL clusters.', '2023-08-12', 'https://openres.org/papers/2023/mvcc-cloud-relational', '10.14778/3611540.3611555'),
    ('Post-Quantum Key Encapsulation in Edge Network Handshakes', 'Evaluating NIST Round 4 lattice-based primitives on ARM microcontrollers with constrained battery envelopes.', '2024-01-25', 'https://openres.org/papers/2024/pq-edge-crypto', '10.1109/TIFS.2024.30129'),
    ('Hybrid Relational-Vector Query Planning: Unifying SQL and Semantic Search', 'We formalize cost-based heuristics to combine relational predicates (WHERE clauses) with top-K vector nearest neighbor searches.', '2024-06-01', 'https://openres.org/papers/2024/hybrid-relational-vector', '10.1145/3626246.3653378'),
    ('Decentralized Privacy-Preserving Genome Assembly', 'A secure multi-party pipeline enabling clinical centers to co-assemble rare disease genomes without disclosing patient reads.', '2023-10-04', 'https://openres.org/papers/2023/secure-genome-assembly', '10.1038/s41587-023-01990-w'),
    ('Provable Convergence Bounds in Non-IID Federated Learning', 'Mathematical derivation of convergence rates for asynchronous gradient aggregation across heterogeneous client topologies.', '2024-02-18', 'https://openres.org/papers/2024/federated-convergence', '10.1609/aaai.v38i11.28910'),
    ('Zero-Knowledge Relational Integrity Proofs for Untrusted Cloud Databases', 'Enabling verifiers to confirm SQL query results over outsourced databases without leaking private column records.', '2024-07-22', 'https://openres.org/papers/2024/zk-relational-proofs', '10.1109/SP.2024.10384'),
    ('Agentic Task Decomposition Using Contextual RAG Memory', 'Investigating recursive sub-goal execution in multi-agent workflows backed by structured episodic knowledge graphs.', '2024-08-30', 'https://openres.org/papers/2024/agentic-rag-decomposition', NULL),
    ('Cache-Oblivious B-Trees on Non-Volatile Persistent Memory', 'Analyzing persistent memory write endurance and cache line flushing behaviors in high-throughput transactional logging.', '2023-05-14', 'https://openres.org/papers/2023/nvram-btree-caching', '10.14778/3598888.3598899'),
    ('Lattice Cryptanalysis Under Quantum Side-Channel Perturbations', 'Simulated side-channel leakage profiles on Kyber and Dilithium hardware accelerators.', '2024-04-11', 'https://openres.org/papers/2024/lattice-side-channel', NULL);

-- ============================================================================
-- 5. INSERT PROJECTS (5 Projects)
-- ============================================================================
INSERT INTO project (name, description, start_date, end_date, status)
VALUES
    ('OmniVector: Next-Gen Vector DB', 'Developing real-time GPU-accelerated HNSW index construction and SIMD distance primitives for PostgreSQL.', '2023-01-01', '2025-12-31', 'active'),
    ('VeriTrust: Post-Quantum Cloud Security', 'Creating hardware security modules and distributed ledgers resilient against quantum adversaries.', '2022-09-01', '2024-08-31', 'completed'),
    ('BioGraph-Connect', 'Federated knowledge graph construction linking clinical genetic profiles with global biomedical literature.', '2023-06-01', '2026-05-31', 'active'),
    ('AeroConsensus: Low-Latency Geo-Replication', 'Design of sub-10ms transactional replication for geographically distributed database clusters.', '2024-02-01', NULL, 'active'),
    ('LegacyDB Migration Toolkit', 'Automated schema refactoring and migration assessment tool for enterprise SQL-92 databases.', '2021-03-01', '2022-06-30', 'completed');

-- ============================================================================
-- 6. INSERT CONFERENCES (7 Conferences)
-- ============================================================================
INSERT INTO conference (name, location, start_date, end_date, submission_deadline, status, url)
VALUES
    ('ACM SIGMOD 2027', 'Berlin, Germany', '2027-06-20', '2027-06-25', '2026-11-15', 'upcoming', 'https://sigmod2027.org'),
    ('VLDB 2027', 'Kyoto, Japan', '2027-08-30', '2027-09-03', '2027-03-01', 'upcoming', 'https://vldb2027.org'),
    ('IEEE Symposium on Security & Privacy 2027', 'San Francisco, USA', '2027-05-18', '2027-05-21', '2026-12-01', 'upcoming', 'https://sp2027.ieee.org'),
    ('NeurIPS 2026', 'Vancouver, Canada', '2026-12-06', '2026-12-12', '2026-05-22', 'upcoming', 'https://neurips.cc/2026'),
    ('ICDE 2026', 'Paris, France', '2026-10-15', '2026-10-25', '2026-04-10', 'ongoing', 'https://icde2026.org'),
    ('Crypto 2025', 'Santa Barbara, USA', '2025-08-17', '2025-08-21', '2025-02-14', 'completed', 'https://iacr.org/crypto2025'),
    ('ACM Symposium on Cloud Computing 2026', 'Rome, Italy', '2026-11-01', '2026-11-04', '2026-06-15', 'upcoming', 'https://socc2026.acm.org');

-- ============================================================================
-- 7. INSERT AUTHORSHIP (Many-to-Many: Researcher <-> Publication)
-- Demonstrating lead authors (order=1) and multi-author publications.
-- ============================================================================
INSERT INTO authorship (researcher_id, publication_id, author_order)
VALUES
    -- Paper 1: Vector Indexing (Rostova lead, Zhou & Patel co-authors)
    (8, 1, 1),
    (2, 1, 2),
    (3, 1, 3),

    -- Paper 2: Byzantine Consensus (Thorne lead, O'Connor co-author)
    (1, 2, 1),
    (7, 2, 2),

    -- Paper 3: Graph-Guided Biomedical (Zhou lead, Picard & Sato co-authors)
    (2, 3, 1),
    (5, 3, 2),
    (9, 3, 3),

    -- Paper 4: MVCC Cloud Relational (Patel lead, O'Connor co-author)
    (3, 4, 1),
    (7, 4, 2),

    -- Paper 5: Post-Quantum Edge (Al-Mansoor lead, Thorne co-author)
    (6, 5, 1),
    (1, 5, 2),

    -- Paper 6: Hybrid Relational-Vector (Patel lead, Rostova & Oswald co-authors)
    (3, 6, 1),
    (8, 6, 2),
    (4, 6, 3),

    -- Paper 7: Decentralized Genome Assembly (Picard lead, Al-Mansoor co-author)
    (5, 7, 1),
    (6, 7, 2),

    -- Paper 8: Non-IID Federated Learning (Okafor lead, Zhou co-author)
    (10, 8, 1),
    (2, 8, 2),

    -- Paper 9: ZK Relational Integrity Proofs (Thorne lead, Patel co-author)
    (1, 9, 1),
    (3, 9, 2),

    -- Paper 10: Agentic Task Decomposition (Oswald lead, Sato co-author)
    (4, 10, 1),
    (9, 10, 2),

    -- Paper 11: Persistent Memory B-Trees (O'Connor lead, Patel co-author)
    (7, 11, 1),
    (3, 11, 2),

    -- Paper 12: Lattice Side-Channel (Al-Mansoor lead)
    (6, 12, 1);

-- ============================================================================
-- 8. INSERT COLLABORATIONS (Many-to-Many: Researcher <-> Researcher)
-- Enforces researcher_id_1 < researcher_id_2 and normalized similarity scores.
-- ============================================================================
INSERT INTO collaboration (researcher_id_1, researcher_id_2, similarity_score)
VALUES
    (1, 6, 0.9250), -- Thorne & Al-Mansoor (Both Post-Quantum & Security)
    (1, 7, 0.8120), -- Thorne & O'Connor (Distributed Consensus)
    (2, 8, 0.8875), -- Zhou & Rostova (Vector Search & Graph ML)
    (2, 9, 0.7930), -- Zhou & Sato (Knowledge Graphs & NLP)
    (2, 10, 0.7420),-- Zhou & Okafor (Graph ML & Federated Learning)
    (3, 7, 0.9410), -- Patel & O'Connor (Database Storage, MVCC, Queries)
    (3, 8, 0.8950), -- Patel & Rostova (Hybrid Relational-Vector Optimization)
    (4, 9, 0.8350), -- Oswald & Sato (Agentic AI & Knowledge Representation)
    (5, 6, 0.7680), -- Picard & Al-Mansoor (Genomics & Privacy-Preserving Computing)
    (6, 8, 0.6540); -- Al-Mansoor & Rostova (Encrypted Vector Search)

-- ============================================================================
-- 9. INSERT RESEARCHER_PROJECT (Many-to-Many: Researcher <-> Project)
-- ============================================================================
INSERT INTO researcher_project (researcher_id, project_id, role, joined_date)
VALUES
    (3, 1, 'Principal Investigator', '2023-01-01'),
    (8, 1, 'Lead Engine Architect', '2023-02-15'),
    (2, 1, 'Vector Graph Specialist', '2023-04-01'),
    (1, 2, 'Co-Principal Investigator', '2022-09-01'),
    (6, 2, 'Lead Cryptographer', '2022-09-01'),
    (5, 3, 'Principal Investigator', '2023-06-01'),
    (2, 3, 'Knowledge Graph Lead', '2023-07-10'),
    (9, 3, 'Ontology Consultant', '2023-08-01'),
    (7, 4, 'Lead Protocol Engineer', '2024-02-01'),
    (1, 4, 'Consensus Verifier', '2024-03-01'),
    (3, 4, 'Storage Advisor', '2024-04-15');

-- ============================================================================
-- 10. INSERT RESEARCHER_TOPIC (Many-to-Many: Researcher <-> Research Topic)
-- ============================================================================
INSERT INTO researcher_topic (researcher_id, topic_id, interest_level)
VALUES
    (1, 1, 'expert'),        -- Thorne: Distributed Consensus
    (1, 5, 'expert'),        -- Thorne: Post-Quantum Cryptography
    (1, 9, 'advanced'),      -- Thorne: Privacy-Preserving Computation
    (2, 2, 'expert'),        -- Zhou: Vector Databases & Search
    (2, 4, 'expert'),        -- Zhou: Graph Neural Networks
    (2, 6, 'advanced'),      -- Zhou: RAG
    (3, 2, 'expert'),        -- Patel: Vector Databases & Search
    (3, 3, 'expert'),        -- Patel: Query Optimization
    (3, 8, 'expert'),        -- Patel: Concurrency
    (4, 6, 'expert'),        -- Oswald: RAG
    (4, 4, 'advanced'),      -- Oswald: Graph Neural Networks
    (5, 7, 'expert'),        -- Picard: Computational Genomics
    (5, 9, 'intermediate'),  -- Picard: Privacy-Preserving
    (6, 5, 'expert'),        -- Al-Mansoor: Post-Quantum Cryptography
    (6, 9, 'expert'),        -- Al-Mansoor: Privacy-Preserving Computation
    (7, 1, 'expert'),        -- O'Connor: Distributed Consensus
    (7, 8, 'expert'),        -- O'Connor: Database Concurrency
    (8, 2, 'expert'),        -- Rostova: Vector Databases
    (8, 3, 'advanced'),      -- Rostova: Query Optimization
    (9, 4, 'expert'),        -- Sato: Graph Neural Networks
    (9, 6, 'advanced'),      -- Sato: RAG
    (10, 10, 'expert'),      -- Okafor: Federated Learning
    (10, 9, 'intermediate'); -- Okafor: Privacy-Preserving

-- ============================================================================
-- 11. INSERT PUBLICATION_TOPIC (Many-to-Many: Publication <-> Research Topic)
-- ============================================================================
INSERT INTO publication_topic (publication_id, topic_id)
VALUES
    (1, 2), -- Paper 1 -> Vector Databases
    (1, 3), -- Paper 1 -> Query Optimization
    (2, 1), -- Paper 2 -> Distributed Consensus
    (3, 4), -- Paper 3 -> Graph Neural Networks
    (3, 7), -- Paper 3 -> Computational Genomics
    (4, 3), -- Paper 4 -> Query Optimization
    (4, 8), -- Paper 4 -> Database Concurrency
    (5, 5), -- Paper 5 -> Post-Quantum Cryptography
    (6, 2), -- Paper 6 -> Vector Databases
    (6, 3), -- Paper 6 -> Query Optimization
    (7, 7), -- Paper 7 -> Computational Genomics
    (7, 9), -- Paper 7 -> Privacy-Preserving Computation
    (8, 10),-- Paper 8 -> Federated Learning
    (9, 9), -- Paper 9 -> Privacy-Preserving Computation
    (9, 8), -- Paper 9 -> Database Concurrency
    (10, 6),-- Paper 10 -> RAG
    (10, 4),-- Paper 10 -> Graph Neural Networks
    (11, 8),-- Paper 11 -> Database Concurrency
    (11, 3),-- Paper 11 -> Query Optimization
    (12, 5);-- Paper 12 -> Post-Quantum Cryptography

-- ============================================================================
-- 12. INSERT CONFERENCE_TOPIC (Many-to-Many: Conference <-> Research Topic)
-- ============================================================================
INSERT INTO conference_topic (conference_id, topic_id)
VALUES
    (1, 2), -- SIGMOD 2027 -> Vector Databases
    (1, 3), -- SIGMOD 2027 -> Query Optimization
    (1, 8), -- SIGMOD 2027 -> Concurrency
    (2, 2), -- VLDB 2027 -> Vector Databases
    (2, 3), -- VLDB 2027 -> Query Optimization
    (2, 1), -- VLDB 2027 -> Distributed Consensus
    (3, 5), -- IEEE S&P 2027 -> Post-Quantum Cryptography
    (3, 9), -- IEEE S&P 2027 -> Privacy-Preserving Computation
    (4, 4), -- NeurIPS 2026 -> Graph Neural Networks
    (4, 6), -- NeurIPS 2026 -> RAG
    (4, 10),-- NeurIPS 2026 -> Federated Learning
    (5, 2), -- ICDE 2026 -> Vector Databases
    (5, 3), -- ICDE 2026 -> Query Optimization
    (6, 5), -- Crypto 2025 -> Post-Quantum Cryptography
    (6, 9), -- Crypto 2025 -> Privacy-Preserving Computation
    (7, 1); -- SOCC 2026 -> Distributed Consensus

-- ============================================================================
-- DML DEMONSTRATIONS: INSERT, SELECT, UPDATE, DELETE
-- Demonstrates fundamental data manipulation operations safely.
-- ============================================================================

-- DML Example 1: INSERT with RETURNING clause (PostgreSQL Feature)
-- Inserts a temporary test topic and returns the newly generated identity key.
INSERT INTO research_topic (name, description, category)
VALUES ('Temporary Benchmark Topic', 'Topic inserted to demonstrate DML statements', 'Benchmarking')
RETURNING topic_id, name, created_at;

-- DML Example 2: SELECT with Filtering and Joins
-- Demonstrates reading active researchers from a specific institution.
SELECT researcher_id, name, email, institution 
FROM researcher 
WHERE institution LIKE '%Institute%' AND is_active = TRUE;

-- DML Example 3: UPDATE with Safe Conditions
-- Updates the status of an ongoing conference to completed when its end date passes.
UPDATE conference
SET status = 'completed',
    updated_at = CURRENT_TIMESTAMP
WHERE end_date < CURRENT_DATE AND status <> 'completed'
RETURNING conference_id, name, status;

-- DML Example 4: DELETE (Safe deletion of the test record created in Example 1)
-- Demonstrates row deletion without impacting core sample relationships.
DELETE FROM research_topic
WHERE name = 'Temporary Benchmark Topic'
RETURNING topic_id, name, 'Successfully deleted test record' AS confirmation_message;
