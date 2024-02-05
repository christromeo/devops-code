#!/bin/bash

# Set the URL of your application's health endpoint
HEALTH_CHECK_URL="http://legal-term.com/app"

RECIPIENT_EMAIL="email@example.com"


FAILURE_THRESHOLD=3

consecutive_failures=0

while true; do

  response=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL")

  if [ "$response" -ne 200 ]; then
    echo "Health check failed! HTTP status code: $response"
    consecutive_failures=$((consecutive_failures + 1))
  else
    echo "Health check passed."
    consecutive_failures=0
  fi

  if [ "$consecutive_failures" -ge "$FAILURE_THRESHOLD" ]; then
    echo "Sending notification..."
    
    echo "Health check failures detected for $FAILURE_THRESHOLD consecutive times at $(date)" | mail -s "Health Check Alert" "$RECIPIENT_EMAIL"
    consecutive_failures=0  
  fi

  sleep 60
done
