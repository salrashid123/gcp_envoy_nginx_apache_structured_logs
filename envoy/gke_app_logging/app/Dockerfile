FROM python:2.7 AS build-env
ADD requirements.txt /
RUN pip install -r requirements.txt

FROM gcr.io/distroless/python2.7
ADD . /app
COPY --from=build-env /usr/local/lib/python2.7/site-packages /usr/local/lib/python2.7/site-packages
WORKDIR /app
ENV PYTHONPATH=/usr/local/lib/python2.7/site-packages
EXPOSE 10000
CMD ["http_server.py"]