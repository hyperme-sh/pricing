FROM python:3.13-alpine@sha256:9ef1a599f863231c3d91e941389bfdc4a2d6070557243d54df1a4e57015b960e AS build
WORKDIR /build

COPY pyproject.toml README.md LICENSE ./
COPY pricing_core ./pricing_core
COPY pricing_service ./pricing_service

RUN python -m venv --without-pip /app/.venv \
    && python -m pip --python /app/.venv install --no-cache-dir ".[service]"

FROM python:3.13-alpine@sha256:9ef1a599f863231c3d91e941389bfdc4a2d6070557243d54df1a4e57015b960e
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:${PATH}"

RUN adduser -D -u 10001 pricing
COPY --from=build /app/.venv /app/.venv
COPY LICENSE /usr/share/licenses/hypermesh-pricing/

USER pricing
EXPOSE 8080

# Exits before listening when PRICING_SERVICE_TOKEN is unset or blank.
# The token is read from the environment at start and is never printed.
ENTRYPOINT ["python", "-m", "pricing_service"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz')"]
