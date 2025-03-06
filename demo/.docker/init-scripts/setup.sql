-- Sample initialization script for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create items table if it doesn't exist
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create initial test data if needed
INSERT INTO items (name, description, is_active)
VALUES 
  ('Welcome to Dev Containers!', 'This is a sample item created during database initialization', true),
  ('React Frontend', 'The frontend is built with React and uses Vite for fast development', true),
  ('FastAPI Backend', 'The backend is built with FastAPI, a modern Python web framework', true),
  ('PostgreSQL Database', 'Data is stored in a PostgreSQL database running in a container', true),
  ('VS Code Integration', 'The dev container is fully integrated with VS Code for a seamless development experience', true),
  ('Hot Reloading', 'Both frontend and backend support hot reloading for rapid development', true),
  ('Docker Compose', 'The entire stack is orchestrated with Docker Compose for easy startup', true)
ON CONFLICT DO NOTHING;