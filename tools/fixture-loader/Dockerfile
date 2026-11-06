ARG PYTHON_IMAGE=python:3.13-slim
FROM ${PYTHON_IMAGE}

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY LICENSE /app/LICENSE
COPY tools/fixture-loader/prepare_isik_data.py /app/tools/fixture-loader/prepare_isik_data.py
COPY testdata/Stufe5/ /app/testdata/Stufe5/
USER 10001:10001
ENTRYPOINT ["python3", "/app/tools/fixture-loader/prepare_isik_data.py"]
CMD ["--help"]
