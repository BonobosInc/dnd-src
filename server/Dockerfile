# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Expose the port
EXPOSE 9000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV SERVER_PORT=9000

# Run the application
CMD ["python", "main.py"]
