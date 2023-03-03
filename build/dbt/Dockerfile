FROM python:3.9.16-slim

WORKDIR /dbt

RUN pip install --upgrade pip
COPY dbt_requirements.txt requirements.txt
RUN pip install -r requirements.txt
ENV DBT_PROFILES_DIR=/dbt