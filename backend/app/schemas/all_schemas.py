from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field

# ----------------- Auth Schemas -----------------
class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: int
    name: str
    email: str
    role: str

class TokenPayload(BaseModel):
    sub: Optional[str] = None
    role: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class ResearcherRegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6)
    institution: Optional[str] = None
    bio: Optional[str] = None
    interests: Optional[List[int]] = None  # topic_ids

# ----------------- Researcher Schemas -----------------
class TopicBase(BaseModel):
    topic_id: int
    name: str
    category: Optional[str] = None
    description: Optional[str] = None

class ResearcherTopicOut(BaseModel):
    topic_id: int
    name: str
    category: str
    interest_level: str

class ResearcherProfile(BaseModel):
    researcher_id: int
    name: str
    email: str
    institution: Optional[str] = None
    bio: Optional[str] = None
    is_active: bool
    created_at: datetime
    topics: List[ResearcherTopicOut] = []
    publications_count: int = 0

class ResearcherUpdate(BaseModel):
    name: Optional[str] = None
    institution: Optional[str] = None
    bio: Optional[str] = None
    topics: Optional[List[dict]] = None  # list of {topic_id: int, interest_level: str}

# ----------------- Publication Schemas -----------------
class PublicationBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=300)
    abstract: Optional[str] = None
    publication_date: date
    url: Optional[str] = None
    doi: Optional[str] = None

class PublicationCreate(PublicationBase):
    topic_ids: Optional[List[int]] = []
    co_author_ids: Optional[List[int]] = []

class PublicationOut(PublicationBase):
    publication_id: int
    created_at: datetime
    authors: Optional[str] = None
    topics: Optional[str] = None
    similarity_score: Optional[float] = None

class SemanticSearchQuery(BaseModel):
    query: str = Field(..., min_length=2)
    limit: int = Field(default=10, ge=1, le=50)
    topic_id: Optional[int] = None
    min_similarity: Optional[float] = Field(default=0.0, ge=0.0, le=1.0)

# ----------------- Recommendation Schemas -----------------
class CollaboratorRecommendation(BaseModel):
    researcher_id: int
    name: str
    institution: Optional[str] = None
    bio: Optional[str] = None
    match_score: float
    shared_topics: List[str] = []
    co_authored_count: int = 0
    top_matching_publication: Optional[str] = None

class ConferenceRecommendation(BaseModel):
    conference_id: int
    name: str
    location: Optional[str] = None
    submission_deadline: date
    start_date: date
    end_date: date
    days_until_deadline: int
    topic_tracks: Optional[str] = None
    match_score: float
    matching_topics: List[str] = []
    status: str

# ----------------- Topic & Analytics -----------------
class ResearchTopicOut(TopicBase):
    publication_count: Optional[int] = 0
    researcher_count: Optional[int] = 0
