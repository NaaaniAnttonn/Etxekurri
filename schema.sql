-- ============================================================
-- SCHEMA SUPABASE v2 — Village Collecte · St-Martin-d'Arrossa
-- Nouveautés : editions, roles (admin/member), montants
-- À exécuter dans : Supabase > SQL Editor
-- ============================================================

-- ── 1. ÉDITIONS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS editions (
  id          TEXT PRIMARY KEY,
  label       TEXT NOT NULL,
  year        INT NOT NULL,
  is_active   BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. GROUPES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS groups (
  id          TEXT PRIMARY KEY,
  edition_id  TEXT REFERENCES editions(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL DEFAULT '#5b8af0',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. MAISONS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS houses (
  id          BIGINT PRIMARY KEY,
  edition_id  TEXT REFERENCES editions(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  lat         DOUBLE PRECISION NOT NULL,
  lng         DOUBLE PRECISION NOT NULL,
  status      TEXT NOT NULL DEFAULT 'à_visiter',
  note        TEXT DEFAULT '',
  amount      NUMERIC(10,2) DEFAULT 0,
  group_id    TEXT REFERENCES groups(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS houses_updated_at ON houses;
CREATE TRIGGER houses_updated_at
  BEFORE UPDATE ON houses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 4. RÔLES / AUTH ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_roles (
  role        TEXT PRIMARY KEY,
  pwd_hash    TEXT NOT NULL
);

-- Mots de passe par défaut (CHANGER après installation !)
--   admin  → "admin2026"
--   member → "fete2026"
INSERT INTO app_roles (role, pwd_hash) VALUES
  ('admin',  '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
  ('member', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LjDL6YGzp2')
ON CONFLICT (role) DO NOTHING;

-- ── 5. ÉDITION 2026 ──────────────────────────────────────────
INSERT INTO editions (id, label, year, is_active) VALUES
  ('2026', 'Fête 2026', 2026, true)
ON CONFLICT (id) DO NOTHING;

-- ── 6. REALTIME ──────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE houses;
ALTER PUBLICATION supabase_realtime ADD TABLE groups;
ALTER PUBLICATION supabase_realtime ADD TABLE editions;

-- ── 7. RLS ───────────────────────────────────────────────────
ALTER TABLE editions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups    ENABLE ROW LEVEL SECURITY;
ALTER TABLE houses    ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_editions"  ON editions  FOR SELECT USING (true);
CREATE POLICY "read_groups"    ON groups    FOR SELECT USING (true);
CREATE POLICY "read_houses"    ON houses    FOR SELECT USING (true);
CREATE POLICY "read_roles"     ON app_roles FOR SELECT USING (true);
CREATE POLICY "write_groups"   ON groups    FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "write_houses"   ON houses    FOR ALL    USING (true) WITH CHECK (true);
CREATE POLICY "write_editions" ON editions  FOR ALL    USING (true) WITH CHECK (true);

-- ── CHANGER UN MOT DE PASSE ──────────────────────────────────
-- Génère un nouveau hash sur https://bcrypt-generator.com (cost=10)
-- puis :
-- UPDATE app_roles SET pwd_hash = 'NOUVEAU_HASH' WHERE role = 'admin';
-- UPDATE app_roles SET pwd_hash = 'NOUVEAU_HASH' WHERE role = 'member';
