coverage run --source=app -m pytest tests/
coverage xml -o coverage.xml
sonar-scanner -D"sonar.projectKey=servers" -D"sonar.sources=." -D"sonar.host.url=http://localhost:9000" -D"sonar.login=sqp_15b8ef73a433bd3305ee1fd65fd3a3933068d769" -D"sonar.python.coverage.reportPaths=coverage.xml"