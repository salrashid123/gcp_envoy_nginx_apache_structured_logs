FROM envoyproxy/envoy:latest as envoy-env

FROM gcr.io/distroless/base
COPY --from=envoy-env /usr/local/bin/envoy /usr/local/bin/envoy
COPY envoy.yaml /apps/envoy.yaml
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/envoy","-l","error", "-c","/apps/envoy.yaml"]