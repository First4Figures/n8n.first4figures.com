-- Create n8n user and grant privileges
CREATE USER n8n WITH PASSWORD 'saUkECGJYdetwQ7q';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
GRANT ALL ON SCHEMA public TO n8n;