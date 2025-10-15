FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and tests
COPY main.py .
COPY __init__.py .
COPY test_main.py .
COPY pytest.ini .

# Run tests during build (build fails if tests fail)
RUN PYTHONPATH=/app pytest test_main.py -v

# Expose port
EXPOSE 5000

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run application
CMD ["python", "main.py"]