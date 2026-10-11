# ---------- Etapa 1: construcción de dependencias con uv ----------
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Instalar solo las dependencias primero (mejor aprovechamiento de la caché)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

# Copiar el código e instalar el proyecto
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev


# ---------- Etapa 2: imagen final ligera ----------
FROM python:3.13-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

# Usuario sin privilegios
RUN groupadd --system app && useradd --system --gid app --home /app app

WORKDIR /app
# El usuario debe poder escribir en /app para crear database.db
RUN chown app:app /app
COPY --from=builder --chown=app:app /app /app

USER app

EXPOSE 8000

# database.db (SQLite) se crea en /app al arrancar
CMD ["fastapi", "run", "main.py", "--host", "0.0.0.0", "--port", "8000"]
