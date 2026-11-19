# Run 06_tests.sql inside the PostgreSQL Docker container
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Running Database Verification & Test Suite (06_tests.sql)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$containerName = "research_intelligence_db"
$dbUser = "postgres"
$dbName = "research_db"

$status = docker inspect -f '{{.State.Running}}' $containerName 2>$null
if ($status -ne "true") {
    Write-Host "Error: Container '$containerName' is not running." -ForegroundColor Red
    Write-Host "Please start it first using: docker compose up -d" -ForegroundColor Yellow
    exit 1
}

Get-Content -Raw "sql/06_tests.sql" | docker exec -i $containerName psql -U $dbUser -d $dbName

Write-Host "`nTest execution completed." -ForegroundColor Cyan
