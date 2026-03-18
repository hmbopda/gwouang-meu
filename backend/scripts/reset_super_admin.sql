-- ════════════════════════════════════════════════════════════════
-- Script : Suppression + re-creation du SUPER_ADMIN
-- Email  : stephanembopda@yahoo.fr
-- MDP    : Gompemeu202407@
-- ════════════════════════════════════════════════════════════════
-- A executer dans le SQL Editor de Supabase (Dashboard > SQL Editor)
-- ════════════════════════════════════════════════════════════════

-- S'assurer que pgcrypto est dispo pour crypt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ────────────────────────────────────────────────────────────────
-- 1. Nettoyage complet de l'ancien user
-- ────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_auth_id UUID;
    v_public_id UUID;
BEGIN
    SELECT id INTO v_auth_id FROM auth.users WHERE email = 'stephanembopda@yahoo.fr';
    SELECT id INTO v_public_id FROM public.users WHERE email = 'stephanembopda@yahoo.fr';

    -- Nettoyer public
    IF v_public_id IS NOT NULL THEN
        DELETE FROM person_invitations WHERE invited_by = v_public_id;
        UPDATE persons SET user_id = NULL WHERE user_id = v_public_id;
        DELETE FROM village_subscriptions WHERE user_id = v_public_id;
        DELETE FROM post_reactions WHERE post_id IN (SELECT id FROM posts WHERE author_id = v_public_id);
        DELETE FROM comments WHERE author_id = v_public_id;
        DELETE FROM comments WHERE post_id IN (SELECT id FROM posts WHERE author_id = v_public_id);
        DELETE FROM posts WHERE author_id = v_public_id;
        DELETE FROM public.users WHERE id = v_public_id;
        RAISE NOTICE 'public.users supprime: %', v_public_id;
    END IF;

    -- Nettoyer auth
    IF v_auth_id IS NOT NULL THEN
        DELETE FROM auth.mfa_factors WHERE user_id = v_auth_id;
        DELETE FROM auth.sessions WHERE user_id = v_auth_id;
        DELETE FROM auth.refresh_tokens WHERE user_id = v_auth_id::text;
        DELETE FROM auth.identities WHERE user_id = v_auth_id;
        DELETE FROM auth.users WHERE id = v_auth_id;
        RAISE NOTICE 'auth.users supprime: %', v_auth_id;
    END IF;
END $$;

-- ────────────────────────────────────────────────────────────────
-- 2. Creer le user dans auth.users
-- ────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_new_id UUID := gen_random_uuid();
BEGIN

    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_sso_user,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        v_new_id,
        'authenticated',
        'authenticated',
        'stephanembopda@yahoo.fr',
        crypt('Gompemeu202407@', gen_salt('bf')),
        NOW(),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        jsonb_build_object('display_name', 'Hugues Stephane MBOPDA'),
        FALSE,
        NOW(),
        NOW()
    );

    -- ────────────────────────────────────────────────────────────
    -- 3. Creer l'identity email
    -- ────────────────────────────────────────────────────────────
    INSERT INTO auth.identities (
        id,
        provider_id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        v_new_id::text,
        v_new_id,
        jsonb_build_object(
            'sub', v_new_id::text,
            'email', 'stephanembopda@yahoo.fr',
            'email_verified', true,
            'phone_verified', false
        ),
        'email',
        NOW(),
        NOW(),
        NOW()
    );

    -- ────────────────────────────────────────────────────────────
    -- 4. Creer dans public.users (SUPER_ADMIN)
    -- ────────────────────────────────────────────────────────────
    INSERT INTO public.users (
        id,
        supabase_id,
        email,
        display_name,
        role,
        country,
        native_language,
        clan,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        v_new_id::text,
        'stephanembopda@yahoo.fr',
        'Hugues Stephane MBOPDA',
        'SUPER_ADMIN',
        'CMR',
        'Francais',
        'Mbopda',
        TRUE,
        NOW(),
        NOW()
    );

    RAISE NOTICE 'SUPER_ADMIN cree avec auth.id = %', v_new_id;

END $$;

-- ────────────────────────────────────────────────────────────────
-- 5. Verification
-- ────────────────────────────────────────────────────────────────
SELECT 'auth.users' AS source, id, email, role, encrypted_password IS NOT NULL AS has_password, email_confirmed_at
FROM auth.users WHERE email = 'stephanembopda@yahoo.fr';

SELECT 'auth.identities' AS source, id, provider, provider_id, user_id
FROM auth.identities WHERE user_id = (SELECT id FROM auth.users WHERE email = 'stephanembopda@yahoo.fr');

SELECT 'public.users' AS source, id, supabase_id, email, role, is_active
FROM public.users WHERE email = 'stephanembopda@yahoo.fr';
