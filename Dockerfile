FROM python:3.11-slim as build

ENV PIP_DEFAULT_TIMEOUT=100 \
    # Allow statements and log messages to immediately appear
    PYTHONUNBUFFERED=1 \
    # disable a pip version check to reduce run-time & log-spam
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    # cache is useless in docker image, so disable to reduce image size
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.3.2

WORKDIR /app
COPY pyproject.toml poetry.lock ./

RUN pip install "poetry==$POETRY_VERSION" \
    && poetry install --no-root --no-ansi --no-interaction \
    && poetry export -f requirements.txt -o requirements.txt


### Final stage
FROM python:3.11-slim as final

WORKDIR /app

COPY --from=build /app/requirements.txt .

RUN set -ex \
    # Upgrade the package index and install security upgrades
    && apt-get update \
    && apt-get upgrade -y \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    # Install dependencies
    && pip install -r requirements.txt

COPY ./data data
COPY ./artifacts artifacts
COPY ./api api

EXPOSE 8000

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
