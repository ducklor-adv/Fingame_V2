-- ============================================================================
-- Fix ACF Placement Function
-- Use real-time COUNT instead of child_count column
-- ============================================================================

CREATE OR REPLACE FUNCTION find_next_acf_parent(inviter_user_id UUID)
RETURNS UUID AS $$
DECLARE
  next_parent_id UUID;
BEGIN
  -- Find the first user in the inviter's network who:
  -- 1. Has less than 5 children (max_children = 5)
  -- 2. Is within 7 levels from the inviter (depth < 7)
  -- 3. Is accepting ACF connections (acf_accepting = TRUE)
  -- Order by: level ASC, created_at ASC (fill from top to bottom, left to right)

  WITH RECURSIVE network_tree AS (
    -- Start from the inviter
    SELECT
      id,
      world_id,
      max_children,
      acf_accepting,
      level,
      created_at,
      1 as depth
    FROM users
    WHERE id = inviter_user_id

    UNION ALL

    -- Recursively get descendants
    SELECT
      u.id,
      u.world_id,
      u.max_children,
      u.acf_accepting,
      u.level,
      u.created_at,
      nt.depth + 1
    FROM users u
    INNER JOIN network_tree nt ON u.parent_id = nt.id
    WHERE nt.depth < 7
  )
  SELECT nt.id INTO next_parent_id
  FROM network_tree nt
  WHERE (
      -- Count actual children in real-time
      SELECT COUNT(*)
      FROM users
      WHERE parent_id = nt.id
    ) < nt.max_children
    AND nt.acf_accepting = TRUE
  ORDER BY nt.level ASC, nt.created_at ASC
  LIMIT 1;

  RETURN next_parent_id;
END;
$$ LANGUAGE plpgsql;

-- Test the function
DO $$
DECLARE
  system_root_uuid UUID;
  next_parent UUID;
  parent_world_id VARCHAR(50);
  parent_username VARCHAR(255);
  parent_child_count INTEGER;
  parent_level INTEGER;
BEGIN
  -- Get system_root UUID
  SELECT id INTO system_root_uuid FROM users WHERE world_id = '25AAA0000';

  IF system_root_uuid IS NULL THEN
    RAISE NOTICE '❌ System root not found';
  ELSE
    -- Find next available parent
    SELECT find_next_acf_parent(system_root_uuid) INTO next_parent;

    IF next_parent IS NULL THEN
      RAISE NOTICE '⚠️  No available parent position found in network';
    ELSE
      RAISE NOTICE '✅ Next available parent found:';
      RAISE NOTICE '   Parent ID: %', next_parent;

      -- Show parent details
      SELECT world_id, username,
        (SELECT COUNT(*) FROM users WHERE parent_id = next_parent),
        level
      INTO parent_world_id, parent_username, parent_child_count, parent_level
      FROM users
      WHERE id = next_parent;

      RAISE NOTICE '   World ID: %', parent_world_id;
      RAISE NOTICE '   Username: %', parent_username;
      RAISE NOTICE '   Current children: %', parent_child_count;
      RAISE NOTICE '   Level: %', parent_level;
    END IF;
  END IF;
END $$;
