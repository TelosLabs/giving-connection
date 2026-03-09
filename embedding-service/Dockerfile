FROM python:3.11-slim

RUN groupadd --system --gid 1000 appuser && \
    useradd appuser --uid 1000 --gid 1000 --create-home --shell /bin/bash

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
