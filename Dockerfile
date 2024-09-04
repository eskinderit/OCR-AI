# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG PYTHON_VERSION=3.10.0
FROM python:${PYTHON_VERSION}-slim as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1


# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/app" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
RUN apt-get update && apt-get upgrade -y && apt-get install build-essential \
    pkg-config cmake poppler-utils libpoppler-cpp-dev tesseract-ocr tesseract-ocr-ita libgl1 curl systemctl -y #redo
	
# install Ollama to use as OCR
RUN curl -fsSL https://ollama.com/install.sh | sh #redo
RUN nohup bash -c "ollama serve &" && sleep 5 && ollama pull llava:7b
RUN systemctl enable ollama #redo
RUN systemctl start ollama #redo

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt

# Switch to the non-privileged user to run the application.
# USER appuser

# Copy the source code into the container.
COPY . /app

WORKDIR /app

# Run the application.
CMD ["jupyter", "lab", "--port=8000", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
