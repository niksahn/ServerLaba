#   coverage run -m pytest
#   coverage xml -o coverage.xml
sonar-scanner \
       -Dsonar.projectKey="servers" \
       -Dsonar.sources=. \
       -Dsonar.host.url="http://localhost:9000" \
       -Dsonar.login="sqp_bc12d6a0e0c678dc6a665a4ccce04ea0d558043b" \
       -Dsonar.python.coverage.reportPaths=coverage.xml