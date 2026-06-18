
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'scentscribe_secret_change_in_prod';


app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: { error: 'Too many requests, please try again later.' }
}));


const pool = new Pool({
  connectionString: process.env.DATABASE_URL ||
    'postgresql://localhost:5432/scentscribe',
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false,
});


async function initDB() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT,
        skin_type TEXT DEFAULT 'normal',
        climate_type TEXT DEFAULT 'tropical',
        is_premium BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS perfumes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        description TEXT,
        family TEXT NOT NULL,
        notes JSONB DEFAULT '[]',
        image_url TEXT,
        ml_owned REAL,
        price REAL,
        purchase_url TEXT,
        rating REAL DEFAULT 0,
        is_wishlist BOOLEAN DEFAULT FALSE,
        best_seasons TEXT[] DEFAULT '{}',
        best_times TEXT[] DEFAULT '{}',
        occasions TEXT[] DEFAULT '{}',
        country_of_origin TEXT,
        launch_year INTEGER,
        perfumer TEXT,
        added_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS journal_entries (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        perfume_id UUID REFERENCES perfumes(id) ON DELETE CASCADE,
        date TIMESTAMPTZ DEFAULT NOW(),
        longevity_rating INTEGER NOT NULL CHECK (longevity_rating BETWEEN 1 AND 10),
        sillage_rating INTEGER NOT NULL CHECK (sillage_rating BETWEEN 1 AND 10),
        projection_rating INTEGER DEFAULT 5 CHECK (projection_rating BETWEEN 1 AND 10),
        mood_rating INTEGER DEFAULT 3,
        notes TEXT,
        weather_condition TEXT,
        weather_temp REAL,
        weather_humidity REAL,
        occasion TEXT,
        moods TEXT[],
        temperature REAL,
        humidity REAL,
        skin_condition TEXT
      );

      CREATE TABLE IF NOT EXISTS trend_data (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        region TEXT NOT NULL,
        family TEXT NOT NULL,
        note_combo TEXT[],
        season TEXT,
        popularity_score REAL DEFAULT 0,
        recorded_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_perfumes_user ON perfumes(user_id);
      CREATE INDEX IF NOT EXISTS idx_journal_user ON journal_entries(user_id);
      CREATE INDEX IF NOT EXISTS idx_journal_perfume ON journal_entries(perfume_id);
      CREATE INDEX IF NOT EXISTS idx_trend_region ON trend_data(region);
    `);
    console.log('✅ Database initialized');
  } finally {
    client.release();
  }
}


function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}


app.post('/api/auth/register', async (req, res) => {
  const { email, password, name } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  try {
    const hash = await bcrypt.hash(password, 12);
    const result = await pool.query(
      'INSERT INTO users (email, password_hash, name) VALUES ($1, $2, $3) RETURNING id, email, name',
      [email.toLowerCase(), hash, name]
    );
    const user = result.rows[0];
    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, {
      expiresIn: '30d'
    });
    res.status(201).json({ user, token });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    res.status(500).json({ error: 'Registration failed' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    const user = result.rows[0];
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, {
      expiresIn: '30d'
    });
    const { password_hash, ...safeUser } = user;
    res.json({ user: safeUser, token });
  } catch {
    res.status(500).json({ error: 'Login failed' });
  }
});


app.get('/api/perfumes', authMiddleware, async (req, res) => {
  const { wishlist } = req.query;
  let query = 'SELECT * FROM perfumes WHERE user_id = $1';
  const params = [req.user.id];
  if (wishlist !== undefined) {
    query += ' AND is_wishlist = $2';
    params.push(wishlist === 'true');
  }
  query += ' ORDER BY added_at DESC';

  try {
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: 'Failed to fetch perfumes' });
  }
});

app.get('/api/perfumes/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM perfumes WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch {
    res.status(500).json({ error: 'Failed to fetch perfume' });
  }
});

app.post('/api/perfumes', authMiddleware, async (req, res) => {
  const {
    name, brand, description, family, notes, image_url,
    ml_owned, price, purchase_url, rating, is_wishlist,
    best_seasons, best_times, occasions, country_of_origin,
    launch_year, perfumer
  } = req.body;

  try {
    const result = await pool.query(`
      INSERT INTO perfumes (
        user_id, name, brand, description, family, notes, image_url,
        ml_owned, price, purchase_url, rating, is_wishlist,
        best_seasons, best_times, occasions, country_of_origin,
        launch_year, perfumer
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18)
      RETURNING *
    `, [
      req.user.id, name, brand, description, family,
      JSON.stringify(notes || []), image_url, ml_owned, price,
      purchase_url, rating || 0, is_wishlist || false,
      best_seasons || [], best_times || [], occasions || [],
      country_of_origin, launch_year, perfumer
    ]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to save perfume', detail: err.message });
  }
});

app.put('/api/perfumes/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  const fields = req.body;
  const allowed = [
    'name', 'brand', 'description', 'family', 'notes', 'rating',
    'is_wishlist', 'ml_owned', 'best_seasons', 'best_times',
    'occasions', 'price'
  ];

  const updates = [];
  const values = [];
  let idx = 1;
  for (const key of allowed) {
    if (fields[key] !== undefined) {
      updates.push(`${key} = $${idx++}`);
      values.push(key === 'notes' ? JSON.stringify(fields[key]) : fields[key]);
    }
  }
  if (!updates.length) return res.status(400).json({ error: 'No valid fields to update' });

  try {
    const result = await pool.query(
      `UPDATE perfumes SET ${updates.join(', ')} WHERE id = $${idx} AND user_id = $${idx + 1} RETURNING *`,
      [...values, id, req.user.id]
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch {
    res.status(500).json({ error: 'Update failed' });
  }
});

app.delete('/api/perfumes/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM perfumes WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    res.json({ success: true });
  } catch {
    res.status(500).json({ error: 'Delete failed' });
  }
});


app.get('/api/journal', authMiddleware, async (req, res) => {
  const { perfume_id, limit = 50 } = req.query;
  let query = `
    SELECT j.*, p.name as perfume_name, p.brand as perfume_brand, p.family
    FROM journal_entries j
    JOIN perfumes p ON p.id = j.perfume_id
    WHERE j.user_id = $1
  `;
  const params = [req.user.id];
  if (perfume_id) {
    query += ` AND j.perfume_id = $2`;
    params.push(perfume_id);
  }
  query += ` ORDER BY j.date DESC LIMIT $${params.length + 1}`;
  params.push(parseInt(limit));

  try {
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: 'Failed to fetch journal' });
  }
});

app.post('/api/journal', authMiddleware, async (req, res) => {
  const {
    perfume_id, longevity_rating, sillage_rating, projection_rating,
    mood_rating, notes, weather_condition, weather_temp, weather_humidity,
    occasion, moods, temperature, humidity
  } = req.body;

  try {
    const result = await pool.query(`
      INSERT INTO journal_entries (
        user_id, perfume_id, longevity_rating, sillage_rating, projection_rating,
        mood_rating, notes, weather_condition, weather_temp, weather_humidity,
        occasion, moods, temperature, humidity
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING *
    `, [
      req.user.id, perfume_id, longevity_rating, sillage_rating,
      projection_rating || 5, mood_rating || 3, notes,
      weather_condition, weather_temp, weather_humidity,
      occasion, moods || [], temperature, humidity
    ]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to save entry', detail: err.message });
  }
});

app.delete('/api/journal/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM journal_entries WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    res.json({ success: true });
  } catch {
    res.status(500).json({ error: 'Delete failed' });
  }
});


app.get('/api/analytics/stats', authMiddleware, async (req, res) => {
  try {
    const [perfumes, journal, avgRating] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM perfumes WHERE user_id=$1 AND is_wishlist=false', [req.user.id]),
      pool.query('SELECT COUNT(*) FROM journal_entries WHERE user_id=$1', [req.user.id]),
      pool.query('SELECT AVG(rating) FROM perfumes WHERE user_id=$1 AND is_wishlist=false', [req.user.id]),
    ]);
    res.json({
      totalPerfumes: parseInt(perfumes.rows[0].count),
      totalLogs: parseInt(journal.rows[0].count),
      avgRating: parseFloat(avgRating.rows[0].avg || 0).toFixed(2),
    });
  } catch {
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

app.get('/api/analytics/performance', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        p.name,
        p.family,
        AVG(j.longevity_rating) as avg_longevity,
        AVG(j.sillage_rating) as avg_sillage,
        AVG(j.projection_rating) as avg_projection,
        COUNT(j.id) as log_count
      FROM perfumes p
      JOIN journal_entries j ON j.perfume_id = p.id
      WHERE j.user_id = $1
      GROUP BY p.id, p.name, p.family
      ORDER BY (AVG(j.longevity_rating) + AVG(j.sillage_rating)) / 2 DESC
    `, [req.user.id]);
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: 'Failed to fetch performance data' });
  }
});


app.get('/api/trends/:region', authMiddleware, async (req, res) => {

  const userResult = await pool.query(
    'SELECT is_premium FROM users WHERE id=$1', [req.user.id]);
  if (!userResult.rows[0]?.is_premium) {
    return res.status(403).json({ error: 'Premium required' });
  }

  try {

    const result = await pool.query(`
      SELECT
        p.family,
        COUNT(*) as popularity,
        AVG(j.longevity_rating) as avg_longevity,
        AVG(j.sillage_rating) as avg_sillage
      FROM journal_entries j
      JOIN perfumes p ON p.id = j.perfume_id
      JOIN users u ON u.id = j.user_id
      WHERE u.climate_type = $1
      GROUP BY p.family
      ORDER BY popularity DESC
      LIMIT 10
    `, [req.params.region]);
    res.json({ region: req.params.region, trends: result.rows });
  } catch {
    res.status(500).json({ error: 'Failed to fetch trends' });
  }
});


app.post('/api/ai/recommend', authMiddleware, async (req, res) => {
  const { temperature, humidity, condition, time_of_day } = req.body;

  try {
    const perfumesResult = await pool.query(
      'SELECT * FROM perfumes WHERE user_id=$1 AND is_wishlist=false',
      [req.user.id]
    );
    const perfumes = perfumesResult.rows;


    const scored = perfumes.map(p => {
      let score = 50;
      const family = p.family;

      const isHot = temperature >= 30;
      const isCold = temperature < 15;
      const isHumid = humidity >= 70;

      if (['fresh', 'aquatic', 'green'].includes(family)) {
        score += isHot ? 30 : isCold ? -20 : 15;
        score += isHumid ? 10 : 0;
      } else if (['oriental', 'gourmand', 'woody'].includes(family)) {
        score += isCold ? 30 : isHot ? -25 : 10;
        score += isHumid ? -10 : 5;
      } else {
        score += 15;
      }

      if (['evening', 'night'].includes(time_of_day) &&
          ['oriental', 'gourmand'].includes(family)) score += 15;
      if (['morning', 'afternoon'].includes(time_of_day) &&
          ['fresh', 'aquatic'].includes(family)) score += 15;

      score += (p.rating / 5) * 10;
      return { ...p, ai_score: Math.min(100, Math.max(0, score)) };
    });

    scored.sort((a, b) => b.ai_score - a.ai_score);
    res.json(scored.slice(0, 5));
  } catch (err) {
    res.status(500).json({ error: 'Recommendation failed', detail: err.message });
  }
});


app.get('/health', (_, res) => {
  res.json({ status: 'ok', service: 'ScentScribe API', version: '1.0.0' });
});


initDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`🌸 ScentScribe API running on port ${PORT}`);
    });
  })
  .catch(err => {
    console.error('❌ DB init failed:', err);
    process.exit(1);
  });

module.exports = app;
