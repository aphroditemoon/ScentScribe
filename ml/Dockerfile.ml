
FROM python:3.11-slim

WORKDIR /app


RUN pip install --no-cache-dir \
    flask==3.0.0 \
    scikit-learn==1.3.2 \
    numpy==1.26.2 \
    pandas==2.1.3 \
    joblib==1.3.2 \
    gunicorn==21.2.0


COPY scent_compatibility_model.pkl .
COPY model_meta.json .
COPY inference_server.py .


RUN useradd -m -u 1001 mluser
USER mluser

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5001/health || exit 1


CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", \
     "--timeout", "30", "inference_server:app"]
