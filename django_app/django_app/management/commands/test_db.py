from django.core.management.base import BaseCommand
from django.db import connection
from django.conf import settings
import sys


class Command(BaseCommand):
    help = 'Test database connectivity'

    def handle(self, *args, **options):
        try:
            # Test basic connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                
            if result:
                self.stdout.write(
                    self.style.SUCCESS('✅ Database connection successful!')
                )
                
                # Get database info
                db_config = settings.DATABASES['default']
                self.stdout.write(f"📊 Database Engine: {db_config['ENGINE']}")
                self.stdout.write(f"🏠 Host: {db_config['HOST']}")
                self.stdout.write(f"🔌 Port: {db_config['PORT']}")
                self.stdout.write(f"📂 Database: {db_config['NAME']}")
                self.stdout.write(f"👤 User: {db_config['USER']}")
                
                # Get PostgreSQL version
                with connection.cursor() as cursor:
                    cursor.execute("SELECT version()")
                    version = cursor.fetchone()[0]
                    self.stdout.write(f"🗄️  PostgreSQL Version: {version.split(',')[0]}")
                
                # Test table creation (optional)
                with connection.cursor() as cursor:
                    cursor.execute("""
                        CREATE TABLE IF NOT EXISTS test_connection (
                            id SERIAL PRIMARY KEY,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """)
                    cursor.execute("INSERT INTO test_connection DEFAULT VALUES RETURNING id")
                    test_id = cursor.fetchone()[0]
                    cursor.execute("DELETE FROM test_connection WHERE id = %s", [test_id])
                    
                self.stdout.write(
                    self.style.SUCCESS('✅ Database read/write operations successful!')
                )
                
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ Database connection failed: {str(e)}')
            )
            sys.exit(1)
