from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
import psycopg
from app.core.config import settings
from app.core.database import get_db_connection
from app.schemas.all_schemas import TokenPayload

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

def get_current_user_token(token: str = Depends(oauth2_scheme)) -> TokenPayload:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        role: str = payload.get("role")
        if user_id is None or role is None:
            raise credentials_exception
        return TokenPayload(sub=user_id, role=role)
    except JWTError:
        raise credentials_exception

def get_current_user(
    token_payload: TokenPayload = Depends(get_current_user_token),
    conn: psycopg.Connection = Depends(get_db_connection),
) -> dict:
    user_id = int(token_payload.sub)
    role = token_payload.role
    
    with conn.cursor() as cur:
        if role in ["admin", "super_admin", "moderator"]:
            cur.execute(
                "SELECT admin_id as id, name, email, role, is_active FROM admin WHERE admin_id = %s;",
                (user_id,)
            )
        else:
            cur.execute(
                "SELECT researcher_id as id, name, email, institution, bio, is_active FROM researcher WHERE researcher_id = %s;",
                (user_id,)
            )
        user = cur.fetchone()
        
    if not user:
        raise HTTPException(status_code=404, detail="User account not found")
    if not user.get("is_active", True):
        raise HTTPException(status_code=400, detail="Inactive user account")
    
    user["role"] = role
    return user

def require_admin(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user.get("role") not in ["admin", "super_admin", "moderator"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The current user does not have administrative privileges",
        )
    return current_user
