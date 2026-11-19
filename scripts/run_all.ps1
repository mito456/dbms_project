# Run all setup scripts sequentially inside the PostgreSQL Docker container
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Research Intelligence Database - Setup & Migration" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$containerName = "research_intelligence_db"
$dbUser = "postgres"
$dbName = "research_db"

# Check if container is running
$status = docker inspect -f '{{.State.Running}}' $containerName 2>$null
if ($status -ne "true") {
    Write-Host "Error: Container '$containerName' is not running." -ForegroundColor Red
    Write-Host "Please start it first using: docker compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[1/3] Executing 01_schema.sql (DDL)..." -ForegroundColor Green
Get-Content -Raw "sql/01_schema.sql" | docker exec -i $containerName psql -U $dbUser -d $dbName

Write-Host "`n[2/3] Executing 02_sample_data.sql (DML)..." -ForegroundColor Green
Get-Content -Raw "sql/02_sample_data.sql" | docker exec -i $containerName psql -U $dbUser -d $dbName

Write-Host "`n[3/3] Executing 04_advanced_sql.sql (Views, Triggers, Functions, Procedures, Indexes)..." -ForegroundColor Green
Get-Content -Raw "sql/04_advanced_sql.sql" | docker exec -i $containerName psql -U $dbUser -d $dbName

Write-Host "`nDatabase setup completed successfully!" -ForegroundColor Cyan
Write-Host "You can now run queries (sql/03_queries.sql) or tests (scripts/run_tests.ps1)." -ForegroundColor Green
