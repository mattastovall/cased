-- Enable RLS on styles table and add a public read policy
ALTER TABLE styles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read styles" ON styles
  FOR SELECT USING (true);;
