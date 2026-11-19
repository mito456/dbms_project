# Connect to PostgreSQL inside Docker with MySQL-style output (pager disabled)
$containerName = "research_intelligence_db"
$dbUser = "postgres"
$dbName = "research_db"

Write-Host "Connecting to $dbName with MySQL-style direct output..." -ForegroundColor Cyan

# PAGER=cat and --pset=pager=off ensure query output prints directly without trapping you in a pager
docker exec -it -e PAGER=cat $containerName psql -U $dbUser -d $dbName --pset=pager=off
