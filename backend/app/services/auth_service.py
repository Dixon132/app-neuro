from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.config import settings
from app.models.user import User
from app.models.schemas import UserCreate

import bcrypt as bcrypt_lib

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        pw_bytes = plain_password.encode('utf-8')
        if len(pw_bytes) > 72:
            pw_bytes = pw_bytes[:72]
        # hashed_password from DB needs to be encoded back to bytes
        hash_bytes = hashed_password.encode('utf-8')
        return bcrypt_lib.checkpw(pw_bytes, hash_bytes)
    except Exception as e:
        print(f"Error verifying password: {e}")
        return False

def get_password_hash(password: str) -> str:
    try:
        pw_bytes = password.encode('utf-8')
        if len(pw_bytes) > 72:
            pw_bytes = pw_bytes[:72]
        # Gen salt and hash
        salt = bcrypt_lib.gensalt(rounds=12)
        hashed_bytes = bcrypt_lib.hashpw(pw_bytes, salt)
        return hashed_bytes.decode('utf-8')
    except Exception as e:
        print(f"Error hashing password: {e}")
        return password

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def authenticate_user(db: Session, username: str, password: str):
    user = db.query(User).filter(User.username == username).first()
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def create_user(db: Session, user: UserCreate, role: str = "user"):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password,
        full_name=user.full_name,
        role=role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = None):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    return username

def ensure_admin_exists(db: Session):
    """Creates a default admin user if none exists."""
    admin = db.query(User).filter(User.role == "admin").first()
    if not admin:
        from app.models.schemas import UserCreate
        admin_data = UserCreate(
            email="admin@eeganalysis.com",
            username="admin",
            password="Admin1234!",
            full_name="Administrador del Sistema"
        )
        create_user(db, admin_data, role="admin")
        print("[Auth] ✅ Admin por defecto creado: admin / Admin1234!")
