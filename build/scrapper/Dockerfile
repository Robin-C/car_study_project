FROM python:3.9.16-slim

WORKDIR /scrapper

RUN pip install --upgrade pip
COPY scrapper_requirements.txt requirements.txt
RUN pip install -r requirements.txt