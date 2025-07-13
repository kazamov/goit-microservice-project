from django.http import JsonResponse
from django.db import connections
from django.core.exceptions import ImproperlyConfigured
import os


def health_check(request):
    """
    Health check endpoint that verifies database connectivity
    """
    try:
        # Test database connection
        db_conn = connections['default']
        cursor = db_conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        
        return JsonResponse({
            'status': 'healthy',
            'database': 'connected',
            'debug': os.environ.get('DJANGO_DEBUG', 'True'),
        })
        
    except Exception as e:
        return JsonResponse({
            'status': 'unhealthy',
            'error': str(e)
        }, status=500)


def root_view(request):
    """
    Simple root view
    """
    return JsonResponse({
        'message': 'Django application is running!',
        'status': 'success'
    })
