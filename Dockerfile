# syntax=docker/dockerfile:1.7

### Stage 1: fetch Go 1.22.x from official image
FROM golang:1.22-alpine3.20 AS gobase

### Stage 2: final worker (Python 3.10, OpenSSH client, ansible-core, FastAPI)
FROM python:3.10-alpine3.20

ARG UID=1000
ARG GID=1000
ARG USERNAME=agent
ARG ANSIBLE_CORE_VERSION="==2.17.*"

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ANSIBLE_HOST_KEY_CHECKING=False \
    PATH="/usr/local/go/bin:${PATH}" \
    # Ensure Ansible uses repo config and inventory by default
    ANSIBLE_CONFIG=/opt/ansible/ansible.cfg \
    ANSIBLE_INVENTORY=/opt/ansible/inventories/hosts.ini \
    # Default private key path (can be overridden by compose env/volume)
    ANSIBLE_PRIVATE_KEY=/home/agent/.ssh/id_ed25519 \
    # Make /workspace imports (webapp/main.py) resolvable as `webapp.*`
    PYTHONPATH=/workspace

# SSH client for Ansible; bash & coreutils for convenience
RUN apk add --no-cache openssh-client bash coreutils

# ansible-core + FastAPI runtime (uvicorn[standard] includes websockets, h11)
RUN python -m pip install --upgrade pip && \
    python -m pip install "ansible-core${ANSIBLE_CORE_VERSION}" fastapi "uvicorn[standard]"

# Copy Go toolchain (if you need `go` inside this image)
COPY --from=gobase /usr/local/go /usr/local/go

# Create non-root user and directories
RUN addgroup -g ${GID} ${USERNAME} && \
    adduser -D -u ${UID} -G ${USERNAME} ${USERNAME} && \
    mkdir -p /workspace /opt/ansible /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /workspace /opt/ansible /home/${USERNAME}

WORKDIR /workspace

# Bring in Ansible content and the web app
COPY ansible/ /opt/ansible/
COPY webapp /workspace/webapp

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Normalize line endings, chmod, and ownership
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
 && chmod 0755 /usr/local/bin/entrypoint.sh \
 && chown -R ${USERNAME}:${USERNAME} /opt/ansible /usr/local/bin/entrypoint.sh /workspace/webapp

USER ${USERNAME}

# Healthcheck: confirms ansible is callable
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD ansible --version >/dev/null 2>&1 || exit 1

# Web UI port (FastAPI/Uvicorn)
EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Serve FastAPI app at webapp/main.py -> webapp.main:app
CMD ["uvicorn", "webapp.main:app", "--host", "0.0.0.0", "--port", "8000"]
