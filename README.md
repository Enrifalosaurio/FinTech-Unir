# FinTech-Unir

API REST con [FastAPI](https://fastapi.tiangolo.com/) y [SQLModel](https://sqlmodel.tiangolo.com/) sobre SQLite.

## Requisitos

- Python 3.13 o superior
- [uv](https://docs.astral.sh/uv/)

## Puesta en marcha

```bash
# Instalar dependencias (crea el entorno virtual .venv)
uv sync

# Lanzar el servidor en modo desarrollo (con recarga automática)
uv run fastapi dev
```

- API: http://127.0.0.1:8000
- Documentación interactiva: http://127.0.0.1:8000/docs

La base de datos `database.db` se crea automáticamente en la raíz del proyecto al arrancar la aplicación.

## Ejecutar con Docker

Requiere tener [Docker](https://docs.docker.com/get-docker/) instalado.

```bash
# Construir la imagen
docker build -t fintech-unir .

# Lanzar el contenedor
docker run -p 8000:8000 fintech-unir
```

- API: http://127.0.0.1:8000
- Documentación interactiva: http://127.0.0.1:8000/docs

Para detenerlo, pulsa `Ctrl+C`. Si prefieres lanzarlo en segundo plano, usa `docker run -d -p 8000:8000 --name fintech-unir fintech-unir` y detenlo con `docker stop fintech-unir`.

> La base de datos `database.db` se crea dentro del contenedor, por lo que sus datos se pierden al eliminarlo.

## Estructura

```
main.py                  # Punto de entrada: app = create_app()
app/
├── app.py               # create_app(): crea FastAPI, registra routers e inicializa la BD
├── db/
│   ├── database.py      # Motor, sesión (get_session) e init_db()
│   └── models/          # Modelos SQLModel (tablas)
└── routers/             # Routers de FastAPI (endpoints)
```


1. Crea un archivo en `app/db/models/`, por ejemplo `accounts.py`:

   ```python
   from uuid import UUID, uuid4
   from sqlmodel import SQLModel, Field


   class Account(SQLModel, table=True):
       __tablename__ = "accounts"

       id: UUID = Field(default_factory=uuid4, primary_key=True)
       user_id: UUID = Field(foreign_key="users.id")
       balance: float = Field(default=0)
   ```

2. Importa el modelo en `app/db/database.py` para que `init_db()` cree su tabla:

   ```python
   from app.db.models.accounts import Account
   ```

   > `SQLModel.metadata.create_all()` solo crea las tablas de los modelos que ya se han importado. También ignora las tablas existentes: si cambias un modelo que ya tiene tabla, tendrás que borrar `database.db` en desarrollo.

## Crear un nuevo router

1. Crea un archivo en `app/routers/`, por ejemplo `accounts_router.py`:

   ```python
   from fastapi import APIRouter, Depends
   from sqlmodel import Session, select
   from app.db.database import get_session
   from app.db.models.accounts import Account


   router = APIRouter(
       prefix="/accounts",
       tags=["accounts"],
   )


   @router.get("/")
   def read_accounts(session: Session = Depends(get_session)):
       return session.exec(select(Account)).all()
   ```

2. Regístralo en `create_app()` dentro de `app/app.py`:

   ```python
   from app.routers.accounts_router import router as accounts_router

   def create_app() -> FastAPI:
       app = FastAPI(lifespan=lifespan)
       app.include_router(users_router)
       app.include_router(accounts_router)
       return app
   ```

Los nuevos endpoints aparecerán automáticamente en `/docs`.

Actualización del readme para la Actividad grupal: pull requests en GitHub de la asignatura Entornos de Integración y Entrega Continua.
## Modelo de Datos: 

### Usuario (`User`)

| Atributo | Tipo | Primaria | Único | Descripción / Por defecto |
| :--- | :--- | :---: | :---: | :--- |
| `id` | `UUID` | Sí | Sí | Identificador único del usuario (generado automáticamente mediante `uuid4`). |
| `username` | `str` | No | Sí | Nombre de usuario único para autenticación/identificación. |
| `email` | `str` | No | Sí | Correo electrónico único del usuario. |
| `password` | `str` | No | No | Contraseña del usuario (hash). |
