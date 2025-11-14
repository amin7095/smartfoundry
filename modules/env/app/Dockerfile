FROM python:3.10-slim
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir flask psycopg2-binary requests boto3
ENV FLASK_APP=app.py
CMD ["python3","app.py"]
