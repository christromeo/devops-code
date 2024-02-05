# Defining the parent image
FROM python:3.11-slim

# Set the working directory to /app
WORKDIR /app

# Copy only the necessary files for poetry
COPY pyproject.toml poetry.lock /app/

# Install poetry and project dependencies
RUN pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-interaction --no-ansi

# Copy the rest of the application code
COPY . /app

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV FLASK_APP=./src/api.py

# Run api.py when the container launches
CMD ["poetry", "run", "flask", "run", "--host=0.0.0.0"]