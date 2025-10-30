FROM python:3.9-slim
RUN pip install flask
WORKDIR /opt/python
COPY app.py .
ENV FLASK_APP=app.py
EXPOSE 8090
CMD ["flask", "run", "--host=0.0.0.0", "--port=8090"]

