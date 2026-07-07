-- P8: 仕入先設定拡張 - lead_time_days カラム追加
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS lead_time_days INT NOT NULL DEFAULT 7;
