#!/usr/bin/env pwsh
# Local Application Test Script

Write-Host "🚀 Testing Todo List Application Locally" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Test 1: Check if containers are running
Write-Host "`n1. Checking container status..." -ForegroundColor Yellow
$containers = docker-compose ps --format json | ConvertFrom-Json
foreach ($container in $containers) {
    if ($container.State -eq "running") {
        Write-Host "✅ $($container.Service) is running on $($container.Publishers)" -ForegroundColor Green
    } else {
        Write-Host "❌ $($container.Service) is not running" -ForegroundColor Red
    }
}

# Test 2: Test Backend API directly
Write-Host "`n2. Testing Backend API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5001" -Method GET
    Write-Host "✅ Backend root endpoint: $($response.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend root endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Test Frontend
Write-Host "`n3. Testing Frontend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081" -Method HEAD
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Frontend is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Frontend failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test API through Frontend Proxy
Write-Host "`n4. Testing API through Frontend Proxy..." -ForegroundColor Yellow
try {
    $todos = Invoke-RestMethod -Uri "http://localhost:8081/api/todos" -Method GET
    Write-Host "✅ API proxy working - Current todos: $($todos.Count)" -ForegroundColor Green
} catch {
    Write-Host "❌ API proxy failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: CRUD Operations
Write-Host "`n5. Testing CRUD Operations..." -ForegroundColor Yellow

# Create
try {
    $newTodo = @{
        text = "Test todo created at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    } | ConvertTo-Json
    
    $created = Invoke-RestMethod -Uri "http://localhost:8081/api/todos" -Method POST -Body $newTodo -ContentType "application/json"
    Write-Host "✅ CREATE: Todo created with ID: $($created._id)" -ForegroundColor Green
    
    # Update
    $update = @{
        completed = $true
    } | ConvertTo-Json
    
    $updated = Invoke-RestMethod -Uri "http://localhost:8081/api/todos/$($created._id)" -Method PATCH -Body $update -ContentType "application/json"
    Write-Host "✅ UPDATE: Todo marked as completed: $($updated.completed)" -ForegroundColor Green
    
    # Delete
    $deleted = Invoke-RestMethod -Uri "http://localhost:8081/api/todos/$($created._id)" -Method DELETE
    Write-Host "✅ DELETE: $($deleted.message)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ CRUD operations failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Database Persistence
Write-Host "`n6. Testing Database Persistence..." -ForegroundColor Yellow
try {
    $dbResult = docker exec project-db-1 psql -U user -d mydb -t -c "SELECT COUNT(*) FROM todos;"
    $todoCount = $dbResult.Trim()
    Write-Host "✅ Database contains $todoCount todos" -ForegroundColor Green
} catch {
    Write-Host "❌ Database test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n🎉 Local Testing Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Frontend URL: http://localhost:8081" -ForegroundColor Cyan
Write-Host "Backend API: http://localhost:5001" -ForegroundColor Cyan
Write-Host "Database: localhost:5432 (user/pass/mydb)" -ForegroundColor Cyan
Write-Host "`nTo stop the application: docker-compose down" -ForegroundColor Yellow