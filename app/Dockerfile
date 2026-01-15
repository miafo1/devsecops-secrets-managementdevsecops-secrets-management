FROM python:3.9-slim

WORKDIR /app

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Switch to non-root user
USER appuser

EXPOSE 5000

# Entrypoint will be overridden by the injection script in the final setup
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
