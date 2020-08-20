#!/bin/bash

_environment="${2:-environment}"
_project="${1:-project}"

echo "====running tests for $_project in $_environment===="
mvn test -pl $_project -Dkarate.env=$_environment
aws s3 cp ./target/cucumber-html-reports s3://folio-gulfstream.s3.amazonaws.com/
