from datetime import datetime, timedelta
from typing import Optional, Any, Union
from jose import jwt
import bcrypt
from app.core.config import settings

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password.encode("utf-8"), salt)
    return hashed.decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not hashed_password:
        return False
    # If legacy mock hash or sample data placeholder
    if hashed_password.startswith("$2b$12$hash_") or "simulatedHash" in hashed_password:
        # Allow default password for seed data demo accounts: e.g. "password" or matching username/role
        if plain_password in ["password", "admin123", "secret"]:
            return True
        # Also check direct match if testing plain
        if plain_password == hashed_password:
            return True
        return False

    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False

def create_access_token(subject: Union[str, Any], role: str, expires_delta: Optional[timedelta] = None) -> str:
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "role": role,
    }
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt
