# ---------- Builder ----------
FROM python:3.13-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       gcc \
       libcurl4-openssl-dev \
       libssl-dev \
       libpq-dev \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt \
    && rm -rf /var/lib/apt/lists/*


# ---------- Runtime ----------
FROM python:3.13-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libcurl4 \
       libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

RUN groupadd --system appgroup \
    && useradd --system --gid appgroup --create-home appuser

COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8000

CMD ["gunicorn", "hc.wsgi:application", "--bind", "0.0.0.0:8000"]