from fastapi import APIRouter, Depends, HTTPException, status
import psycopg
from app.core.security import verify_password, hash_password, create_access_token
from app.core.database import get_db_connection
from app.schemas.all_schemas import (
    Token,
    LoginRequest,
    ResearcherRegisterRequest,
    ResearcherProfile
)
from app.services.activity_service import log_research_activity

router = APIRouter()

@router.post("/register", response_model=Token)
def register_researcher(
    req: ResearcherRegisterRequest,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    with conn.cursor() as cur:
        # Check if email exists
        cur.execute("SELECT researcher_id FROM researcher WHERE email = %s;", (req.email,))
        if cur.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A researcher with this email is already registered."
            )
        
        # Check if also in admin
        cur.execute("SELECT admin_id FROM admin WHERE email = %s;", (req.email,))
        if cur.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is reserved by administrative staff."
            )
            
        hashed_pwd = hash_password(req.password)
        cur.execute(
            """
            INSERT INTO researcher (name, email, password_hash, institution, bio, is_active)
            VALUES (%s, %s, %s, %s, %s, TRUE)
            RETURNING researcher_id, name, email;
            """,
            (req.name, req.email, hashed_pwd, req.institution, req.bio)
        )
        new_user = cur.fetchone()
        user_id = new_user["researcher_id"]
        
        # Insert initial interests if provided
        if req.interests:
            for topic_id in req.interests:
                cur.execute(
                    """
                    INSERT INTO researcher_topic (researcher_id, topic_id, interest_level)
                    VALUES (%s, %s, 'intermediate')
                    ON CONFLICT DO NOTHING;
                    """,
                    (user_id, topic_id)
                )
        conn.commit()

    token = create_access_token(subject=user_id, role="researcher")
    log_research_activity(
        action="USER_REGISTER",
        user_id=user_id,
        user_email=req.email,
        role="researcher",
        details={"name": req.name, "institution": req.institution}
    )
    
    return Token(
        access_token=token,
        token_type="bearer",
        user_id=user_id,
        name=req.name,
        email=req.email,
        role="researcher"
    )

@router.post("/login", response_model=Token)
def login(
    req: LoginRequest,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    with conn.cursor() as cur:
        # Try researcher login first
        cur.execute(
            "SELECT researcher_id, name, email, password_hash, is_active FROM researcher WHERE email = %s;",
            (req.email,)
        )
        user = cur.fetchone()
        role = "researcher"
        
        # If not found in researcher, try admin
        if not user:
            cur.execute(
                "SELECT admin_id, name, email, password_hash, role, is_active FROM admin WHERE email = %s;",
                (req.email,)
            )
            user = cur.fetchone()
            if user:
                role = user["role"]

        if not user or not verify_password(req.password, user["password_hash"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        if not user["is_active"]:
            raise HTTPException(status_code=400, detail="Account is disabled")

        user_id = user.get("researcher_id") or user.get("admin_id")
        token = create_access_token(subject=user_id, role=role)
        
        log_research_activity(
            action="USER_LOGIN",
            user_id=user_id,
            user_email=user["email"],
            role=role,
            details={"name": user["name"]}
        )

        return Token(
            access_token=token,
            token_type="bearer",
            user_id=user_id,
            name=user["name"],
            email=user["email"],
            role=role
        )
