FROM python:3.11

COPY . .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 80

CMD ["uvicorn", "my_api:app", "--host", "0.0.0.0", "--port", "80"]
