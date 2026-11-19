from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Research Collaboration & Publication Intelligence System"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # PostgreSQL Configuration
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "research_db"
    POSTGRES_PORT: str = "5433"
    DB_HOST: str = "localhost"
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5433/research_db"
    
    # MongoDB Configuration
    MONGO_URI: str = "mongodb://localhost:27017/"
    MONGO_DB_NAME: str = "research_intelligence"
    
    # Security & JWT Configuration
    SECRET_KEY: str = "super-secret-key-change-in-production-dbms-project-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    
    # Vector Search & Embedding Model
    EMBEDDING_MODEL_NAME: str = "BAAI/bge-base-en-v1.5"
    EMBEDDING_DIM: int = 768

    class Config:
        env_file = Path(__file__).resolve().parents[2] / ".env"
        extra = "ignore"

settings = Settings()
