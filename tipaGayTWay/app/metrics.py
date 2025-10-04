from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Request, Response
import time

# HTTP request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status_code']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

# Active connections
http_requests_in_flight = Gauge(
    'http_requests_in_flight',
    'Number of HTTP requests currently being processed'
)

# Custom business metrics
api_calls_total = Counter(
    'api_calls_total',
    'Total API calls',
    ['service', 'operation']
)

def setup_metrics_middleware(app):
    """Setup Prometheus metrics middleware for FastAPI"""
    
    @app.middleware("http")
    async def metrics_middleware(request: Request, call_next):
        # Increment active connections
        http_requests_in_flight.inc()
        
        start_time = time.time()
        
        try:
            response = await call_next(request)
            
            # Record metrics
            http_requests_total.labels(
                method=request.method,
                endpoint=request.url.path,
                status_code=response.status_code
            ).inc()
            
            http_request_duration_seconds.labels(
                method=request.method,
                endpoint=request.url.path
            ).observe(time.time() - start_time)
            
            return response
            
        finally:
            # Decrement active connections
            http_requests_in_flight.dec()
    
    @app.get("/metrics")
    async def metrics():
        """Prometheus metrics endpoint"""
        return Response(
            generate_latest(),
            media_type=CONTENT_TYPE_LATEST
        )
