from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session, select
from app.db.database import get_session
from app.db.models.users import User, UserCreate, UserPublic


router = APIRouter(
    prefix="/users",
    tags=["users"],
)


@router.get("/", response_model=list[UserPublic])
def read_users(session: Session = Depends(get_session)):
    return session.exec(select(User)).all()


@router.get("/{user_id}", response_model=UserPublic)
def read_user(user_id: UUID, session: Session = Depends(get_session)):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/", response_model=UserPublic, status_code=201)
def create_user(user_in: UserCreate, session: Session = Depends(get_session)):
    user = User.model_validate(user_in)
    session.add(user)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=409, detail="Username or email already exists")
    session.refresh(user)
    return user

@router.delete("/{user_id}", response_model=UserPublic)
def delete_user(user_id: UUID, session: Session = Depends(get_session)):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    session.delete(user)
    session.commit()
    return user
