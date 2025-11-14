#!/bin/bash
for i in {1..20}; do
  if curl -s http://localhost:1080/status | grep -q "running"; then break; fi
  sleep 1
done
curl -s -X PUT "http://localhost:1080/mockserver/expectation" -d '{ "httpRequest": {"method": "POST","path":"/mocked/payment"}, "httpResponse": {"statusCode":200,"body":"{\"status\":\"approved\",\"mock\":true}"} , "times": {"unlimited": true}}' -H "Content-Type: application/json" || true
