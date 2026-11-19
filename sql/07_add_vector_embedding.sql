-- Migration: Add pgvector extension and embedding column to publication table
CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE publication 
ADD COLUMN IF NOT EXISTS embedding vector(768);

CREATE INDEX IF NOT EXISTS idx_publication_embedding_hnsw 
ON publication USING hnsw (embedding vector_cosine_ops);

