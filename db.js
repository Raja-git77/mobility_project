require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Configure PostgreSQL connection pool with DATABASE_URL or discrete env variables
const poolConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.DATABASE_URL.includes('localhost') ? false : { rejectUnauthorized: false },
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    }
  : {
      user: process.env.DB_USER || process.env.PGUSER || 'postgres',
      host: process.env.DB_HOST || process.env.PGHOST || 'localhost',
      database: process.env.DB_NAME || process.env.PGDATABASE || 'postgres',
      password: process.env.DB_PASSWORD || process.env.PGPASSWORD || '',
      port: parseInt(process.env.DB_PORT || process.env.PGPORT || '5432', 10),
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    };

const pool = new Pool(poolConfig);

pool.on('connect', () => {
  // connection established
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
});

/**
 * Initializes database tables using schema.sql
 */
async function initDatabase() {
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const sql = fs.readFileSync(schemaPath, 'utf8');
      await pool.query(sql);
      console.log('✅ PostgreSQL Schema & Seed Data Initialized Successfully!');
    } else {
      console.warn('⚠️ schema.sql file not found. Skipping auto-migration.');
    }
  } catch (err) {
    console.error('❌ Error executing database schema:', err.message);
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  initDatabase,
};
