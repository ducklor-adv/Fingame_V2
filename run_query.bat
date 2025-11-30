@echo off
REM Run SQL query from file or command line
REM Usage: run_query.bat "SELECT * FROM users;"
REM    or: run_query.bat quick_queries.sql

if "%~1"=="" (
    echo Usage: run_query.bat "SQL QUERY" or run_query.bat filename.sql
    exit /b 1
)

if exist "%~1" (
    REM File exists - run from file
    docker exec -i fingrow-postgres psql -U fingrow_user -d fingrow < "%~1"
) else (
    REM Run direct query
    docker exec fingrow-postgres psql -U fingrow_user -d fingrow -c "%~1"
)
