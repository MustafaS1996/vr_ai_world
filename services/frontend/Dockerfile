# Frontend Service Dockerfile
FROM python:3.10-alpine

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache curl

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Copy static files
COPY static/ ./static/

# Create non-root user
RUN adduser -D -s /bin/sh appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=3000"]