FROM amazonlinux
RUN yum -y update && \
    yum -y install python3 python3-pip && \
    yum clean all
RUN pip3 install flask
WORKDIR /opt/python
COPY app.py .
ENV FLASK_APP=app.py
CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]
EXPOSE 8080
