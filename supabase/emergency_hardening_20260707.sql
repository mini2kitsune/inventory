-- ============================================================
-- 応急処置: RLS 二重防御 (2026-07-07)
-- 目的: Fable 5 レビュー指摘への対応
--   TENANT_ID クライアント公開 + 公開サインアップの組合せから、
--   第三者が tenant_members に不正 INSERT できる可能性を潰す。
--
-- 適用: Supabase 管理画面 SQL Editor で全文貼り付け → Run
-- 影響:
--   - 殿(既存owner)のログイン・利用: 影響なし
--   - bootstrap_tenant() 関数: SECURITY DEFINER ゆえ RLS バイパス・影響なし
--   - 第三者の tenant_members への不正 INSERT: 阻止される
-- ============================================================

-- PATCH 1: members_insert を安全版に強制置換
-- （もし SQL⑤(bootstrap_policies)が誤って適用されていた場合の応急処置）
DROP POLICY IF EXISTS "members_insert" ON public.tenant_members;

CREATE POLICY "members_insert" ON public.tenant_members
  FOR INSERT WITH CHECK (
    -- 既存の owner だけが新メンバーを追加できる
    -- (bootstrap_tenant() は SECURITY DEFINER なのでこのポリシーをバイパス)
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_members
      WHERE user_id = auth.uid()
        AND role = 'owner'
    )
  );

-- ============================================================
-- 完了確認クエリ
-- ============================================================
-- 現在の members_insert ポリシーが安全版か確認:
-- SELECT policyname, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'tenant_members' AND policyname = 'members_insert';
--
-- 期待される with_check: (tenant_id IN ( SELECT tenant_members.tenant_id
--   FROM tenant_members WHERE ((user_id = auth.uid()) AND (role = 'owner'))))

-- ============================================================
-- 補足: 現在の tenant_members の中身確認（殿ご自身の user_id を知りたい時）
-- ============================================================
-- SELECT tenant_id, user_id, role, created_at
-- FROM public.tenant_members
-- WHERE tenant_id = '4177e1bd-a31d-42bb-9e8f-0f1acddf3b45';
