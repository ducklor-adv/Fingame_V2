-- Adminer 5.4.1 PostgreSQL 16.11 dump

DROP FUNCTION IF EXISTS "auto_update_upline_id";;
CREATE FUNCTION "auto_update_upline_id" () RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
  -- Calculate and set upline_id
  NEW.upline_id := get_upline_ids(NEW.id);
  RETURN NEW;
END;
';

DROP FUNCTION IF EXISTS "find_next_acf_parent";;
CREATE FUNCTION "find_next_acf_parent" (IN "inviter_user_id" uuid) RETURNS uuid LANGUAGE plpgsql AS '
DECLARE
  next_parent_id UUID;
BEGIN
  -- Find the first user in the inviter''s network who:
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
';

DROP FUNCTION IF EXISTS "generate_insurance_order_number";;
CREATE FUNCTION "generate_insurance_order_number" () RETURNS text LANGUAGE plpgsql AS '
DECLARE
    new_order_number TEXT;
    counter INT;
BEGIN
    -- สร้าง order number รูปแบบ INS-YYYYMMDD-NNNN
    SELECT COUNT(*) + 1 INTO counter
    FROM insurance_orders
    WHERE DATE(created_at) = CURRENT_DATE;

    new_order_number := ''INS-'' || TO_CHAR(CURRENT_DATE, ''YYYYMMDD'') || ''-'' || LPAD(counter::TEXT, 4, ''0'');

    RETURN new_order_number;
END;
';

DROP FUNCTION IF EXISTS "get_upline_ids";;
CREATE FUNCTION "get_upline_ids" (IN "start_user_id" uuid) RETURNS jsonb LANGUAGE plpgsql AS '
DECLARE
  upline_array UUID[] := ARRAY[]::UUID[];
  current_parent_id UUID;
  level_count INTEGER := 0;
  max_levels INTEGER := 6;
BEGIN
  -- Get the parent_id of the starting user
  SELECT parent_id INTO current_parent_id
  FROM users
  WHERE id = start_user_id;

  -- If no parent, return empty array
  IF current_parent_id IS NULL THEN
    RETURN ''[]''::jsonb;
  END IF;

  -- Traverse up the tree, collecting parent IDs
  WHILE current_parent_id IS NOT NULL AND level_count < max_levels LOOP
    -- Add current parent to array
    upline_array := upline_array || current_parent_id;
    level_count := level_count + 1;

    -- Get the next parent
    SELECT parent_id INTO current_parent_id
    FROM users
    WHERE id = current_parent_id;
  END LOOP;

  -- Convert UUID array to JSONB array
  RETURN to_jsonb(upline_array);
END;
';

DROP FUNCTION IF EXISTS "update_insurance_product_updated_at";;
CREATE FUNCTION "update_insurance_product_updated_at" () RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
';

DROP FUNCTION IF EXISTS "update_updated_at_column";;
CREATE FUNCTION "update_updated_at_column" () RETURNS trigger LANGUAGE plpgsql AS '
      BEGIN
          NEW.updated_at = EXTRACT(EPOCH FROM NOW())::BIGINT * 1000;
          RETURN NEW;
      END;
      ';

DROP FUNCTION IF EXISTS "update_user_insurance_selections_deactivated_at";;
CREATE FUNCTION "update_user_insurance_selections_deactivated_at" () RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
  IF OLD.is_active = true AND NEW.is_active = false THEN
    NEW.deactivated_at = NOW();
  END IF;

  IF OLD.is_active = false AND NEW.is_active = true THEN
    NEW.deactivated_at = NULL;
  END IF;

  RETURN NEW;
END;
';

DROP FUNCTION IF EXISTS "update_user_insurance_selections_updated_at";;
CREATE FUNCTION "update_user_insurance_selections_updated_at" () RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
';

DROP FUNCTION IF EXISTS "uuid_generate_v1";;
CREATE FUNCTION "uuid_generate_v1" () RETURNS uuid LANGUAGE c AS 'uuid_generate_v1';

DROP FUNCTION IF EXISTS "uuid_generate_v1mc";;
CREATE FUNCTION "uuid_generate_v1mc" () RETURNS uuid LANGUAGE c AS 'uuid_generate_v1mc';

DROP FUNCTION IF EXISTS "uuid_generate_v3";;
CREATE FUNCTION "uuid_generate_v3" (IN "namespace" uuid, IN "name" text) RETURNS uuid LANGUAGE c AS 'uuid_generate_v3';

DROP FUNCTION IF EXISTS "uuid_generate_v4";;
CREATE FUNCTION "uuid_generate_v4" () RETURNS uuid LANGUAGE c AS 'uuid_generate_v4';

DROP FUNCTION IF EXISTS "uuid_generate_v5";;
CREATE FUNCTION "uuid_generate_v5" (IN "namespace" uuid, IN "name" text) RETURNS uuid LANGUAGE c AS 'uuid_generate_v5';

DROP FUNCTION IF EXISTS "uuid_nil";;
CREATE FUNCTION "uuid_nil" () RETURNS uuid LANGUAGE c AS 'uuid_nil';

DROP FUNCTION IF EXISTS "uuid_ns_dns";;
CREATE FUNCTION "uuid_ns_dns" () RETURNS uuid LANGUAGE c AS 'uuid_ns_dns';

DROP FUNCTION IF EXISTS "uuid_ns_oid";;
CREATE FUNCTION "uuid_ns_oid" () RETURNS uuid LANGUAGE c AS 'uuid_ns_oid';

DROP FUNCTION IF EXISTS "uuid_ns_url";;
CREATE FUNCTION "uuid_ns_url" () RETURNS uuid LANGUAGE c AS 'uuid_ns_url';

DROP FUNCTION IF EXISTS "uuid_ns_x500";;
CREATE FUNCTION "uuid_ns_x500" () RETURNS uuid LANGUAGE c AS 'uuid_ns_x500';

DROP TABLE IF EXISTS "addresses";
CREATE TABLE "public"."addresses" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "label" character varying(50) NOT NULL,
    "recipient_name" character varying(255) NOT NULL,
    "phone" character varying(50),
    "address_line1" character varying(500) NOT NULL,
    "address_line2" character varying(500),
    "city" character varying(100) NOT NULL,
    "state_province" character varying(100),
    "postal_code" character varying(20) NOT NULL,
    "country" character varying(3) NOT NULL,
    "coordinates" jsonb,
    "is_default" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_addresses_user_id ON public.addresses USING btree (user_id);


DELIMITER ;;

CREATE TRIGGER "update_addresses_updated_at" BEFORE UPDATE ON "public"."addresses" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP TABLE IF EXISTS "categories";
CREATE TABLE "public"."categories" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "name" character varying(255) NOT NULL,
    "name_th" character varying(255),
    "description" text,
    "icon" character varying(255),
    "is_active" boolean DEFAULT true,
    "sort_order" integer DEFAULT '0',
    "slug" character varying(255),
    "parent_id" uuid,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_categories_slug ON public.categories USING btree (slug);

CREATE INDEX idx_categories_parent_id ON public.categories USING btree (parent_id);

CREATE INDEX idx_categories_is_active ON public.categories USING btree (is_active) WHERE (is_active = true);


DROP TABLE IF EXISTS "chat_rooms";
CREATE TABLE "public"."chat_rooms" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "buyer_id" uuid NOT NULL,
    "seller_id" uuid NOT NULL,
    "product_id" uuid,
    "last_message" text,
    "last_message_at" timestamp,
    "current_offer_amount" numeric(15,2),
    "current_offer_currency" character varying(3),
    "offer_status" character varying(50) DEFAULT 'none',
    "is_active" boolean DEFAULT true,
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "chat_rooms_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_chat_rooms_buyer_id ON public.chat_rooms USING btree (buyer_id);

CREATE INDEX idx_chat_rooms_seller_id ON public.chat_rooms USING btree (seller_id);

CREATE INDEX idx_chat_rooms_product_id ON public.chat_rooms USING btree (product_id);


DELIMITER ;;

CREATE TRIGGER "update_chat_rooms_updated_at" BEFORE UPDATE ON "public"."chat_rooms" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP TABLE IF EXISTS "commission_pool_distribution";
CREATE TABLE "public"."commission_pool_distribution" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "insurance_order_id" uuid,
    "recipient_user_id" uuid NOT NULL,
    "recipient_role" character varying(20) NOT NULL,
    "upline_level" integer,
    "share_portion" numeric(10,6) NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "transaction_type" character varying(20) DEFAULT 'commission',
    "description" text,
    "distributed_at" timestamp DEFAULT now(),
    CONSTRAINT "commission_pool_distribution_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

COMMENT ON TABLE "public"."commission_pool_distribution" IS 'เก็บรายละเอียดการกระจาย Commission Pool (45% ของ Commission) และการใช้ Finpoint';

COMMENT ON COLUMN "public"."commission_pool_distribution"."upline_level" IS '0=buyer, 1-6=upline level, NULL=system_root/finpoint_spent';

COMMENT ON COLUMN "public"."commission_pool_distribution"."amount" IS 'จำนวน Finpoint (+ = รับ, - = จ่าย)';

CREATE INDEX idx_cpd_recipient ON public.commission_pool_distribution USING btree (recipient_user_id);

CREATE INDEX idx_cpd_order ON public.commission_pool_distribution USING btree (insurance_order_id);

CREATE INDEX idx_cpd_distributed_at ON public.commission_pool_distribution USING btree (distributed_at);

CREATE INDEX idx_cpd_type ON public.commission_pool_distribution USING btree (transaction_type);

INSERT INTO "commission_pool_distribution" ("id", "insurance_order_id", "recipient_user_id", "recipient_role", "upline_level", "share_portion", "amount", "transaction_type", "description", "distributed_at") VALUES
('b23aa2f8-3864-455e-8a5e-671a8f981da6',	'6396b060-82b0-4686-afb8-b996b6a08ecf',	'00000000-0000-0000-0000-000000000000',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('6801315a-aeb0-4efc-9063-2d4f0cbe64fe',	'6396b060-82b0-4686-afb8-b996b6a08ecf',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.857143,	43.77,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3fa925e0-30e0-4e7a-83dc-57d98df3b60a',	'910f6af0-8002-4065-ae72-b503f09c5838',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('90e9532c-d089-4ce1-926b-6700f34a9084',	'910f6af0-8002-4065-ae72-b503f09c5838',	'00000000-0000-0000-0000-000000000000',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dbef546e-27d2-4663-a6cb-4665652dc329',	'910f6af0-8002-4065-ae72-b503f09c5838',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.714286,	36.47,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('1e6d4d49-281d-4c46-9ef7-d0e7c98286be',	'ddff261e-5f48-4c08-b691-f0a4787c75a8',	'ba601584-060a-4f03-8702-7abbf09353c0',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('7074841b-f21c-4963-9009-89fb2fd89ede',	'ddff261e-5f48-4c08-b691-f0a4787c75a8',	'00000000-0000-0000-0000-000000000000',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('771d1d15-d3e3-459a-bd69-e801258dbdc2',	'ddff261e-5f48-4c08-b691-f0a4787c75a8',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.714286,	36.47,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('7af0e412-cdb8-463b-88a2-2141ac40c126',	'd4ad3210-f90d-4b81-ab8a-2e1591c74865',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('81b98183-e53c-4f52-b5d9-a002e1b84ab3',	'd4ad3210-f90d-4b81-ab8a-2e1591c74865',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('d05439c7-d172-47d0-b800-2117b19f925b',	'd4ad3210-f90d-4b81-ab8a-2e1591c74865',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('21f82e28-872b-4ffe-b460-92de4eadd24b',	'd4ad3210-f90d-4b81-ab8a-2e1591c74865',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3c9f93ed-2304-4fad-958f-6a432b47f17d',	'd9664c80-b3c7-4cb6-bc91-741672f50861',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('8ebc2864-7c64-4699-a6cf-cac17b855bc2',	'd9664c80-b3c7-4cb6-bc91-741672f50861',	'00000000-0000-0000-0000-000000000000',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('1c6fbb8e-786a-47df-89d2-75fd1e79c86f',	'd9664c80-b3c7-4cb6-bc91-741672f50861',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.714286,	36.47,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('d50fbf92-adfd-4d15-b322-60fc5d345d5c',	'bcfbeac3-9d8b-4492-ba09-27ba4a067f96',	'b86923e4-ae78-4dad-a5d1-070f72006c83',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('b784560f-e630-412d-af24-63ca09a3e853',	'bcfbeac3-9d8b-4492-ba09-27ba4a067f96',	'00000000-0000-0000-0000-000000000000',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('20977ccf-d54f-498a-ac71-40242a26b78b',	'bcfbeac3-9d8b-4492-ba09-27ba4a067f96',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.714286,	36.47,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('6e9a9065-3474-4b5e-ba39-0d537d87c85b',	'00d4e7c9-1b9e-4741-91a7-19c708027df5',	'aeaba876-100a-4da3-ae90-ae175bfdd5aa',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('c479a124-bd58-4c88-a2aa-98044b27d176',	'00d4e7c9-1b9e-4741-91a7-19c708027df5',	'00000000-0000-0000-0000-000000000000',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('1d3e481e-b85e-4028-a35a-06415ed3d5a7',	'00d4e7c9-1b9e-4741-91a7-19c708027df5',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.714286,	36.47,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('6debc44b-0dcc-4850-a1ac-fc855eb4b78a',	'f694cc93-b57a-4df1-9ba9-284ffa47e9e6',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('df7da03b-f916-404d-aead-47c0e70d617d',	'f694cc93-b57a-4df1-9ba9-284ffa47e9e6',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('5ab9a0ad-ff1f-4e4e-a8d6-d13698b86031',	'f694cc93-b57a-4df1-9ba9-284ffa47e9e6',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('4a4bd9da-edf5-4d05-9f38-bf37a7289c0b',	'f694cc93-b57a-4df1-9ba9-284ffa47e9e6',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('262f79e1-ab7d-4be4-b0d0-592d67efef80',	'609bf585-8b5e-406e-a49c-51d855b21570',	'78e83bc3-7fc2-4528-9909-8154b641fc08',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('393866b3-316e-4045-a5ad-472b9e316fd0',	'609bf585-8b5e-406e-a49c-51d855b21570',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('95c64c17-65de-4c20-a6fb-2b5afe77eae0',	'609bf585-8b5e-406e-a49c-51d855b21570',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('a2aed776-18f2-4e5f-a12a-d209d9bae207',	'609bf585-8b5e-406e-a49c-51d855b21570',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('11a268a5-4968-4554-befc-cd3669a6607a',	'7cf49c37-9384-4526-a0dc-c1fe32b999e5',	'd77ef8b3-df9f-48b7-8eed-485a0a592abd',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dcf0a0d8-d025-443b-bbd3-ee990c0a3994',	'7cf49c37-9384-4526-a0dc-c1fe32b999e5',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3431472c-2c0a-4030-a152-fa72977ce956',	'7cf49c37-9384-4526-a0dc-c1fe32b999e5',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('0c03b5c4-c331-4d38-8fc4-2f29d0ff9393',	'7cf49c37-9384-4526-a0dc-c1fe32b999e5',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dfa0f3fb-14d3-4694-be62-edfec91b20a8',	'204aebe7-b17d-4df7-b301-b7908def25cc',	'7b8b9dc4-4e6a-4c99-8988-6c176e2904c2',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('a392ead2-2b1e-4a03-ad7c-2edb229af8f9',	'204aebe7-b17d-4df7-b301-b7908def25cc',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('05028599-787d-4274-9a5c-941a20f717c4',	'204aebe7-b17d-4df7-b301-b7908def25cc',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('049021ef-d07c-4e62-91d3-738056991a7d',	'204aebe7-b17d-4df7-b301-b7908def25cc',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('37d86b35-34dc-4629-9feb-adf6423a07d1',	'f97dd68b-226d-46a7-815d-c920e9346efd',	'ee579d17-2a8f-46df-9f09-8a7d6e7f49a1',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('5daf80f7-6fbf-4c84-8cf3-3c7487d3eac2',	'f97dd68b-226d-46a7-815d-c920e9346efd',	'ba601584-060a-4f03-8702-7abbf09353c0',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('8df6b972-0136-4004-a6a5-919f5ade26c2',	'f97dd68b-226d-46a7-815d-c920e9346efd',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('2c264006-b37a-403f-ae1d-0dd959a7d82d',	'f97dd68b-226d-46a7-815d-c920e9346efd',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('09a71803-5853-4249-b4bc-f73f7dcb6b3e',	'144efc9c-9e27-4569-ac67-c0739de6bd95',	'56774264-3dbb-4c24-83cb-e9c4b35356c9',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('34df047e-203d-4a7d-a28f-76ca7488d378',	'144efc9c-9e27-4569-ac67-c0739de6bd95',	'ba601584-060a-4f03-8702-7abbf09353c0',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('85293a86-e19a-4ded-9562-835aa4c14bcf',	'144efc9c-9e27-4569-ac67-c0739de6bd95',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('72b5503a-9fc3-484e-8d5a-e9a07ff81a5b',	'144efc9c-9e27-4569-ac67-c0739de6bd95',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('be2fcf32-20e7-46d2-9b8c-d67b90ad834f',	'6ad8b944-ca5a-4000-adcb-bdaaffe4bf05',	'b711b7b8-8dc9-46ea-b70e-787dab4f3813',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('94dd9a3d-de7e-49b6-902d-e7a0da3355f0',	'6ad8b944-ca5a-4000-adcb-bdaaffe4bf05',	'ba601584-060a-4f03-8702-7abbf09353c0',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('4d2f4ecd-7f79-480a-ac5c-901510a642ce',	'6ad8b944-ca5a-4000-adcb-bdaaffe4bf05',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('8d8162a8-fec7-42f7-917e-113e6e2082dd',	'6ad8b944-ca5a-4000-adcb-bdaaffe4bf05',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('bea3d666-979b-4681-86be-fc880fe2d3be',	'c4369b94-8e5d-40f6-a189-f5342e1fd503',	'1ea69140-4932-406c-b5a6-86b37a6a31e5',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('14ee300f-20e7-4837-9262-8a46c2e878cc',	'c4369b94-8e5d-40f6-a189-f5342e1fd503',	'ba601584-060a-4f03-8702-7abbf09353c0',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('aaa05dc3-7365-4eaa-8dee-0bf25cc327fb',	'c4369b94-8e5d-40f6-a189-f5342e1fd503',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3ced6e8e-5654-4f7d-af5a-aeb117950ab7',	'c4369b94-8e5d-40f6-a189-f5342e1fd503',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('376283e5-1294-44b0-803f-5a09b7b1d45a',	'8c9bc3b6-48f1-4e04-a5c5-a52e65cb6701',	'fdce7838-c916-4bf8-ae67-bea31ab9306c',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('28f0e0b0-aebe-4558-9555-9166c3005010',	'8c9bc3b6-48f1-4e04-a5c5-a52e65cb6701',	'ba601584-060a-4f03-8702-7abbf09353c0',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('56bbb396-77da-4765-9f59-7ebf4332c2c7',	'8c9bc3b6-48f1-4e04-a5c5-a52e65cb6701',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('64ba88ef-a8ae-4818-b690-c7f0c26199f1',	'8c9bc3b6-48f1-4e04-a5c5-a52e65cb6701',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('c20961e2-09a6-485c-a6ca-ea69f02de786',	'6101a252-b9df-47a1-8ff1-3be3e6044faf',	'47aa4075-d780-4092-9bae-0903074777a5',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('0a7b2855-4921-4b38-b453-9f24ffc97909',	'6101a252-b9df-47a1-8ff1-3be3e6044faf',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('d46b344e-fe54-47b5-b353-622c5921f7a5',	'6101a252-b9df-47a1-8ff1-3be3e6044faf',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('90e2bdd7-d8a9-47f9-a22e-4be3950d0b67',	'6101a252-b9df-47a1-8ff1-3be3e6044faf',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('aa84c647-98a1-408d-861d-40e7e0ca4b70',	'6a03f822-d17b-44ac-858e-66c91b17db50',	'1ad833d5-5d45-4e70-9018-0b8ac15943e4',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('e6a0c3b8-102f-46b9-9a1d-0cf61707361d',	'6a03f822-d17b-44ac-858e-66c91b17db50',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('96a27222-c405-4ca3-bfde-7145b29d9029',	'6a03f822-d17b-44ac-858e-66c91b17db50',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('b8dab3c1-1188-495b-af06-2f12630a46db',	'6a03f822-d17b-44ac-858e-66c91b17db50',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('ce56adda-c129-4857-9a6f-d3d200a15514',	'88d66729-bea0-4787-9890-8e045bf895f5',	'b134399b-f98e-48da-ae37-ef78ca6ef2aa',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('31a42333-569d-489d-9c2a-b001250c7861',	'88d66729-bea0-4787-9890-8e045bf895f5',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3878a1ce-19e6-40eb-9022-f69b79abdc16',	'88d66729-bea0-4787-9890-8e045bf895f5',	'00000000-0000-0000-0000-000000000000',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('66056bd5-5eb9-40c8-aefb-e9ba368b0be2',	'88d66729-bea0-4787-9890-8e045bf895f5',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.571429,	29.18,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('e6e48e1d-f181-45c5-a705-ee70115b5535',	'07697710-82ba-4417-a94d-5013a9b1eb6e',	'eb717701-bf90-4983-8dce-0796de17fa5f',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('77786b2e-c06c-4303-a01f-a5bafe694451',	'07697710-82ba-4417-a94d-5013a9b1eb6e',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('4b141ffb-6035-4416-9a0d-f7a7239e7b2b',	'07697710-82ba-4417-a94d-5013a9b1eb6e',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('09307bd4-bd2f-4215-8ade-047ebf92deaa',	'07697710-82ba-4417-a94d-5013a9b1eb6e',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('5cd06bd4-f7ec-450f-8d8d-dd9b3d54a794',	'07697710-82ba-4417-a94d-5013a9b1eb6e',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('172b6856-916c-4698-9390-983566dac9c9',	'50083ca5-78d3-46ce-80b4-f42315420d07',	'1a2430a1-fcee-4c25-a3db-de79d54780f2',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('6478e748-3571-48ec-baba-cc3b564babef',	'50083ca5-78d3-46ce-80b4-f42315420d07',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('90f9b496-54bd-4d6f-887f-baa41d098337',	'50083ca5-78d3-46ce-80b4-f42315420d07',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('8de9ebc5-0e31-4af1-aa0e-50cf33ca1fc1',	'50083ca5-78d3-46ce-80b4-f42315420d07',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('5fbfe503-bc71-4c14-b468-a5f2a2b1deb3',	'50083ca5-78d3-46ce-80b4-f42315420d07',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('ade67ab4-9a52-4fba-b3ed-8849da6fde7e',	'ea0f1f0a-b9bf-4cc0-9e98-5836f6e43dbe',	'8411e766-ec96-4cc9-ab6d-4d3a706b4265',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('097ff49a-4dbd-4e95-8ef0-a61e221ca99a',	'ea0f1f0a-b9bf-4cc0-9e98-5836f6e43dbe',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('18da9ef9-7876-4b97-88f9-092a0677b61b',	'ea0f1f0a-b9bf-4cc0-9e98-5836f6e43dbe',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('a8c4f839-d33d-4fd9-8141-c703b2ce4d94',	'ea0f1f0a-b9bf-4cc0-9e98-5836f6e43dbe',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('498623bc-0d92-4c48-9ff8-9e114c20fb10',	'ea0f1f0a-b9bf-4cc0-9e98-5836f6e43dbe',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dcf98faa-9b18-4b93-9cba-f5a9b7da5bd3',	'dede0e81-8366-4f1d-b87a-0e5dbde2b032',	'76af7b61-4884-4322-8496-a273ae21e803',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('0d0b137b-139a-4c21-950f-30abf27257dd',	'dede0e81-8366-4f1d-b87a-0e5dbde2b032',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('df3d3e86-4d50-4714-a4e8-e3187d3ed337',	'dede0e81-8366-4f1d-b87a-0e5dbde2b032',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('72538bd0-9bfd-4a6a-ac7d-7576e31259b4',	'dede0e81-8366-4f1d-b87a-0e5dbde2b032',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dfd32fab-6256-45d6-beb2-b5882aff4b07',	'dede0e81-8366-4f1d-b87a-0e5dbde2b032',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dfc4b813-d17c-4c4c-a37f-de91f6122c32',	'7d0b2307-02e4-4d77-907b-3d7cd966514b',	'f06d4037-5a96-4486-93c1-ae2b2bc8fd7d',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('21f735e8-7b6f-45c7-a177-47f07e9723ce',	'7d0b2307-02e4-4d77-907b-3d7cd966514b',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('9ddbc416-9aa2-4688-84fe-5e2d45aef61b',	'7d0b2307-02e4-4d77-907b-3d7cd966514b',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('d9d19d7c-9326-41ff-a21d-ff6394c71055',	'7d0b2307-02e4-4d77-907b-3d7cd966514b',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('f818506a-dd8e-4afc-955c-a6173d76fa9d',	'7d0b2307-02e4-4d77-907b-3d7cd966514b',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('18a5418b-7bfe-4884-aa55-79a01c640725',	'bd161f67-8149-4ed5-8134-8bbf5c56646a',	'dfd78098-8df3-44bf-82f7-a36c4688fe78',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('1b83c281-bb87-403f-b6bb-5ddccfa5a9f0',	'bd161f67-8149-4ed5-8134-8bbf5c56646a',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('e3754fd0-4f15-4093-be50-e62491313b32',	'bd161f67-8149-4ed5-8134-8bbf5c56646a',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('53472a7b-a90f-4675-926c-c36d367dc703',	'bd161f67-8149-4ed5-8134-8bbf5c56646a',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('07ebfdb7-b67a-41c4-8057-73b286e5959f',	'bd161f67-8149-4ed5-8134-8bbf5c56646a',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('938ffece-03ff-4a4a-ab0e-dc87476fa9f9',	'7eb4cccb-5bf0-44ab-b8f4-90ef1b665812',	'7881fc2e-8cc4-40c2-995f-dd8bacc86189',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('80176a0a-f37f-4824-aae6-602290551554',	'7eb4cccb-5bf0-44ab-b8f4-90ef1b665812',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('c6bfce0f-5ab6-41d2-abc5-4430dbd9f555',	'7eb4cccb-5bf0-44ab-b8f4-90ef1b665812',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('ce2c991a-3db9-49ba-bd9e-3e9b5ea68b9b',	'7eb4cccb-5bf0-44ab-b8f4-90ef1b665812',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('4a752304-595b-4e05-8835-8bf400aed640',	'7eb4cccb-5bf0-44ab-b8f4-90ef1b665812',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('906ac49a-4141-430b-85f3-182b16d3b0c4',	'ecdabb9a-a82f-441c-a0a4-49deb6d64544',	'8dcd76f7-693d-45fb-b269-df8a0c4fa8c4',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('6d69ae03-05cb-4a13-b7e5-f3f806a59116',	'ecdabb9a-a82f-441c-a0a4-49deb6d64544',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('ce2ab30c-a914-4a25-be99-05022f3fb563',	'ecdabb9a-a82f-441c-a0a4-49deb6d64544',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('648dd0a2-35c1-41c9-8c75-3cc2b76f9a49',	'ecdabb9a-a82f-441c-a0a4-49deb6d64544',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('f4abee20-e53b-4cc8-b789-100092ad3ab4',	'ecdabb9a-a82f-441c-a0a4-49deb6d64544',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('05bddb04-f1fd-42c0-883b-9ef09ee49ff8',	'4f5e648a-43ce-4571-9b2f-480ff2806b2b',	'78408b7e-6f37-48b1-bccd-4f9e55f0b93a',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('a073df22-1686-4507-b31b-3b320ca0972e',	'4f5e648a-43ce-4571-9b2f-480ff2806b2b',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3baf03cc-c716-41c8-b67b-c7b31dd05c14',	'4f5e648a-43ce-4571-9b2f-480ff2806b2b',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('484a004d-fd24-47cc-b723-71f3fbdda06d',	'4f5e648a-43ce-4571-9b2f-480ff2806b2b',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('5ae472fc-7c63-4a17-96fe-cfe382c17e42',	'4f5e648a-43ce-4571-9b2f-480ff2806b2b',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('7f593bc2-9f97-477f-a9a1-f91293198f26',	'972a9620-521b-4a77-aea6-f6ba37841d0c',	'bc9c8410-213d-4f6a-9f62-9de859c65e26',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('c7809951-b8dd-46ad-90cc-f23bc754a5c8',	'972a9620-521b-4a77-aea6-f6ba37841d0c',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('ecc683a2-74e6-4f1a-8ecb-597248e87d6f',	'972a9620-521b-4a77-aea6-f6ba37841d0c',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('16ffff36-24e5-4a3d-8787-8f3928546822',	'972a9620-521b-4a77-aea6-f6ba37841d0c',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('b6445ba5-b3c1-4949-b70a-b391e423af34',	'972a9620-521b-4a77-aea6-f6ba37841d0c',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dea64ba2-b861-4500-9f4b-dbaa4c4314f8',	'ef35ff7e-5e59-4b14-a61c-bc3a01e5e017',	'96dcd69e-47b0-4456-b576-d5972156f71b',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('1abcd62b-9c8a-4dee-ba9f-b2e6e6326177',	'ef35ff7e-5e59-4b14-a61c-bc3a01e5e017',	'78e83bc3-7fc2-4528-9909-8154b641fc08',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('875e5a71-9280-407e-9a51-fa65da31e3aa',	'ef35ff7e-5e59-4b14-a61c-bc3a01e5e017',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('5c7cd632-2112-496e-84bd-e7c20336b095',	'ef35ff7e-5e59-4b14-a61c-bc3a01e5e017',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dd45bd0c-1e12-4a97-9d9b-785e9122c308',	'ef35ff7e-5e59-4b14-a61c-bc3a01e5e017',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('ee9a44af-31bd-4b85-83e4-720a1486fc4d',	'da94d478-c72a-4d9e-9d21-c06da9cce4ae',	'01fae03e-fbf6-4bc4-9f2b-df20e599c20e',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('d0124cc4-563b-42bd-a378-0b77f40c5f1c',	'da94d478-c72a-4d9e-9d21-c06da9cce4ae',	'78e83bc3-7fc2-4528-9909-8154b641fc08',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('b93a4460-8423-494e-92a8-430058c81a95',	'da94d478-c72a-4d9e-9d21-c06da9cce4ae',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('dd0b312b-0c7f-4d80-a432-c7e660e72c39',	'da94d478-c72a-4d9e-9d21-c06da9cce4ae',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('3259932d-ecf3-4865-b01d-dd0952152510',	'da94d478-c72a-4d9e-9d21-c06da9cce4ae',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('4a402e67-8386-4153-a72d-4444e071cebb',	'caa835ea-12c0-4a06-9bd7-1addcd2a5cdc',	'76647ce0-b7e6-4a69-b43c-86f301cec801',	'buyer',	0,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('311f2d95-7d5f-4f80-9cbd-51ed8547e6dd',	'caa835ea-12c0-4a06-9bd7-1addcd2a5cdc',	'78e83bc3-7fc2-4528-9909-8154b641fc08',	'upline_1',	1,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('115ad7a0-beb4-4a53-aa86-258af857b473',	'caa835ea-12c0-4a06-9bd7-1addcd2a5cdc',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'upline_2',	2,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('1e045ff4-7a4a-47da-b2d9-9f184b0b4564',	'caa835ea-12c0-4a06-9bd7-1addcd2a5cdc',	'00000000-0000-0000-0000-000000000000',	'upline_3',	3,	0.142857,	7.29,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('65a840b8-7e27-405f-93a6-adb71cc12816',	'caa835ea-12c0-4a06-9bd7-1addcd2a5cdc',	'00000000-0000-0000-0000-000000000000',	'system_root',	NULL,	0.428571,	21.88,	'commission',	NULL,	'2025-12-02 17:27:07.161373'),
('4f05e085-de62-4696-863b-46a4b7de9017',	NULL,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'demo_purchase',	NULL,	0.000000,	500.00,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 12:57:46.522871'),
('f5109c70-873d-437c-92f4-0b2f83a8cc61',	NULL,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'demo_purchase',	NULL,	0.000000,	10.00,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 12:58:37.782419'),
('a46c0329-604a-417a-af7f-552f778a3afd',	NULL,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'demo_purchase',	NULL,	0.000000,	41669.00,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 13:00:06.691506'),
('339a9555-6da1-4113-bec8-b6967b5ab18d',	NULL,	'ba601584-060a-4f03-8702-7abbf09353c0',	'demo_purchase',	NULL,	0.000000,	712.76,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 13:18:32.35988'),
('ddfe5b49-ff1f-489f-b5d5-f96fc753b5e2',	'5017c706-6ddb-466e-a797-b2a4e7e96637',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'finpoint_spent',	NULL,	0.000000,	-645.50,	'commission',	NULL,	'2025-12-03 13:35:46.87711'),
('22a7e08b-2fcb-4210-b087-52b604c51c31',	'a9c0fa7f-cd51-4a3a-a8a7-1e386da829ea',	'ba601584-060a-4f03-8702-7abbf09353c0',	'finpoint_spent',	NULL,	0.000000,	-756.50,	'commission',	NULL,	'2025-12-03 13:44:26.778393'),
('51e1b24f-e6f5-431e-b593-80de5e9e84a3',	'fdc2d088-5dba-41ce-9201-65dd7cacdb84',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'finpoint_spent',	NULL,	0.000000,	-645.50,	'commission',	NULL,	'2025-12-03 13:49:45.875496'),
('9033045e-7afa-449d-abb5-7dff6cfc703f',	'e4a0357f-1c50-4b5a-9972-1f7015542c2a',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'finpoint_spent',	NULL,	0.000000,	-4815.00,	'commission',	NULL,	'2025-12-03 13:50:24.692465'),
('8190ea2d-6af8-45dc-a37e-1287a968ce03',	'e6c29ea1-95a8-4a65-95dc-8c62214e1453',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'finpoint_spent',	NULL,	0.000000,	-12500.00,	'commission',	NULL,	'2025-12-03 13:50:42.476153'),
('db4e24f0-40da-4046-a824-066170bbded6',	NULL,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'demo_purchase',	NULL,	0.000000,	11288.49,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 13:50:56.496043'),
('32cfd6ff-066c-44cc-9c18-298577ec2611',	NULL,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'demo_purchase',	NULL,	0.000000,	11288.49,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 13:51:04.236471'),
('47d0c4f7-a03c-4ad7-aeed-7517c4a5ef0b',	'375471ef-6033-4751-b897-1e547fd54eb4',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'finpoint_spent',	NULL,	0.000000,	-35000.00,	'commission',	NULL,	'2025-12-03 14:02:52.165254'),
('996e3341-3d48-4e19-b891-74c4a2114a5c',	NULL,	'ba601584-060a-4f03-8702-7abbf09353c0',	'demo_purchase',	NULL,	0.000000,	756.50,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-03 14:24:47.918296'),
('5c6c92d5-11a2-4133-8676-5234ce2a30e6',	NULL,	'ba601584-060a-4f03-8702-7abbf09353c0',	'demo_purchase',	NULL,	0.000000,	4058.50,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-04 00:10:57.072206'),
('cff15b12-cf39-434b-ad0d-3b866fce9bfa',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'finpoint_spent',	NULL,	0.000000,	-4815.00,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('27045657-817b-456b-af77-a520ae3b0feb',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'00000000-0000-0000-0000-000000000000',	'upline',	1,	35.000000,	127.58,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('82787853-97f6-4eac-9b56-cc6421ca880d',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'no_upline_bonus',	2,	25.000000,	91.13,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('e51beb4d-76a5-4fe3-b81e-d03f147e9358',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'no_upline_bonus',	3,	15.000000,	54.68,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('e349b717-1eac-4ff3-9474-f1eb6f927d2b',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'no_upline_bonus',	4,	10.000000,	36.45,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('53d8400f-5691-4b17-9d6d-3113c5c23905',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'no_upline_bonus',	5,	7.000000,	25.52,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('4d54ab5a-5d18-41af-9a40-2fcb7aa5e4d5',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'no_upline_bonus',	6,	5.000000,	18.23,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('2f5caf65-fa5e-4275-aa7d-006b13eb9f78',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'no_upline_bonus',	7,	3.000000,	10.94,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('d32be33a-de47-4f02-9643-e77b45bf91de',	'8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'ba601584-060a-4f03-8702-7abbf09353c0',	'self_bonus',	NULL,	20.000000,	72.90,	'commission',	NULL,	'2025-12-04 00:23:59.128901'),
('3ecd1171-f45c-420c-8126-3b25adba0fd9',	NULL,	'ba601584-060a-4f03-8702-7abbf09353c0',	'demo_purchase',	NULL,	0.000000,	8190.15,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-04 00:28:13.130205'),
('c39f2766-26a4-4c37-8d2e-a2f80873bd14',	'c4c1e629-117f-43d6-85f5-b8648aa3e3fd',	'ba601584-060a-4f03-8702-7abbf09353c0',	'finpoint_spent',	NULL,	0.000000,	-8500.00,	'commission',	NULL,	'2025-12-04 00:28:56.164728'),
('34cdab23-3165-4d57-8c7c-d8c0578a6b10',	'c4c1e629-117f-43d6-85f5-b8648aa3e3fd',	'00000000-0000-0000-0000-000000000000',	'upline',	1,	35.000000,	226.80,	'commission',	NULL,	'2025-12-04 00:28:56.164728'),
('d50cf5c5-b835-4c7d-9bbf-58ec6b37cb73',	'c4c1e629-117f-43d6-85f5-b8648aa3e3fd',	'ba601584-060a-4f03-8702-7abbf09353c0',	'self_bonus',	NULL,	20.000000,	129.60,	'commission',	NULL,	'2025-12-04 00:28:56.164728'),
('5f739240-286a-4ed0-ad51-839089d60789',	NULL,	'ba601584-060a-4f03-8702-7abbf09353c0',	'demo_purchase',	NULL,	0.000000,	4685.40,	'demo',	'เติม Demo Finpoint เพื่อทดสอบระบบ',	'2025-12-05 12:51:19.846254'),
('541dc844-1ee4-4629-a07d-b1d548e0241b',	'3855d0b7-a258-40ad-9cba-9d47ad15c928',	'00000000-0000-0000-0000-000000000000',	'finpoint_spent',	NULL,	0.000000,	-645.50,	'commission',	NULL,	'2025-12-06 00:31:15.281973'),
('5272f68d-7799-4019-92c3-8fea36099d1b',	'3855d0b7-a258-40ad-9cba-9d47ad15c928',	'00000000-0000-0000-0000-000000000000',	'self_bonus',	NULL,	15.000000,	6.08,	'commission',	NULL,	'2025-12-06 00:31:15.281973');

DROP TABLE IF EXISTS "earnings";
CREATE TABLE "public"."earnings" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "source_user_id" uuid NOT NULL,
    "order_id" uuid,
    "source_order_id" uuid,
    "source_type" character varying(100),
    "earning_type" character varying(100),
    "amount_wld" numeric(15,8) NOT NULL,
    "amount_local" numeric(15,2) NOT NULL,
    "currency_code" character varying(3) DEFAULT 'THB',
    "level" integer,
    "percentage" numeric(5,2),
    "referral_level" integer,
    "commission_rate" numeric(5,2),
    "status" character varying(50) DEFAULT 'pending',
    "paid_at" timestamp,
    "payment_transaction_id" character varying(255),
    "description" text,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "earnings_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_earnings_user_id ON public.earnings USING btree (user_id);

CREATE INDEX idx_earnings_source_user_id ON public.earnings USING btree (source_user_id);

CREATE INDEX idx_earnings_status ON public.earnings USING btree (status);

CREATE INDEX idx_earnings_created_at ON public.earnings USING btree (created_at);


DROP TABLE IF EXISTS "favorites";
CREATE TABLE "public"."favorites" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "product_id" uuid NOT NULL,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "favorites_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX favorites_user_id_product_id_key ON public.favorites USING btree (user_id, product_id);

CREATE INDEX idx_favorites_user_id ON public.favorites USING btree (user_id);

CREATE INDEX idx_favorites_product_id ON public.favorites USING btree (product_id);


DROP VIEW IF EXISTS "insurance_order_detail";
CREATE TABLE "insurance_order_detail" ("order_id" uuid, "order_number" character varying(50), "buyer_user_id" uuid, "buyer_username" character varying(255), "insurance_product_id" uuid, "insurance_name" character varying(120), "premium_amount" numeric(12,2), "commission_pool" numeric(12,2), "payment_method" character varying(20), "finpoint_spent" numeric(12,2), "recipient_user_id" uuid, "recipient_username" character varying(255), "recipient_role" character varying(20), "upline_level" integer, "share_portion" numeric(10,6), "amount" numeric(12,2), "distributed_at" timestamp);


DROP TABLE IF EXISTS "insurance_orders";
CREATE TABLE "public"."insurance_orders" (
    "id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "order_number" character varying(50) NOT NULL,
    "user_id" uuid NOT NULL,
    "insurance_product_id" uuid NOT NULL,
    "premium_amount" numeric(12,2) NOT NULL,
    "commission_rate" numeric(5,2) NOT NULL,
    "total_commission" numeric(12,2) NOT NULL,
    "management_fee" numeric(12,2) NOT NULL,
    "seller_commission" numeric(12,2) NOT NULL,
    "commission_pool" numeric(12,2) NOT NULL,
    "payment_method" character varying(20) NOT NULL,
    "finpoint_spent" numeric(12,2) DEFAULT '0',
    "order_status" character varying(50) DEFAULT 'completed',
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "insurance_orders_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "insurance_orders_payment_method_check" CHECK (((payment_method)::text = ANY ((ARRAY['cash'::character varying, 'finpoint'::character varying])::text[])))
)
WITH (oids = false);

COMMENT ON TABLE "public"."insurance_orders" IS 'เก็บประวัติการซื้อประกันของแต่ละ user';

CREATE UNIQUE INDEX insurance_orders_order_number_key ON public.insurance_orders USING btree (order_number);

CREATE INDEX idx_io_user ON public.insurance_orders USING btree (user_id);

CREATE INDEX idx_io_product ON public.insurance_orders USING btree (insurance_product_id);

CREATE INDEX idx_io_created_at ON public.insurance_orders USING btree (created_at);

INSERT INTO "insurance_orders" ("id", "order_number", "user_id", "insurance_product_id", "premium_amount", "commission_rate", "total_commission", "management_fee", "seller_commission", "commission_pool", "payment_method", "finpoint_spent", "order_status", "created_at", "updated_at") VALUES
('6396b060-82b0-4686-afb8-b996b6a08ecf',	'INS-20251202-0001',	'00000000-0000-0000-0000-000000000000',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('910f6af0-8002-4065-ae72-b503f09c5838',	'INS-20251202-0002',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('ddff261e-5f48-4c08-b691-f0a4787c75a8',	'INS-20251202-0003',	'ba601584-060a-4f03-8702-7abbf09353c0',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('d4ad3210-f90d-4b81-ab8a-2e1591c74865',	'INS-20251202-0004',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('d9664c80-b3c7-4cb6-bc91-741672f50861',	'INS-20251202-0005',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('bcfbeac3-9d8b-4492-ba09-27ba4a067f96',	'INS-20251202-0006',	'b86923e4-ae78-4dad-a5d1-070f72006c83',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('00d4e7c9-1b9e-4741-91a7-19c708027df5',	'INS-20251202-0007',	'aeaba876-100a-4da3-ae90-ae175bfdd5aa',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('f694cc93-b57a-4df1-9ba9-284ffa47e9e6',	'INS-20251202-0008',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('609bf585-8b5e-406e-a49c-51d855b21570',	'INS-20251202-0009',	'78e83bc3-7fc2-4528-9909-8154b641fc08',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('7cf49c37-9384-4526-a0dc-c1fe32b999e5',	'INS-20251202-0010',	'd77ef8b3-df9f-48b7-8eed-485a0a592abd',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('204aebe7-b17d-4df7-b301-b7908def25cc',	'INS-20251202-0011',	'7b8b9dc4-4e6a-4c99-8988-6c176e2904c2',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('f97dd68b-226d-46a7-815d-c920e9346efd',	'INS-20251202-0012',	'ee579d17-2a8f-46df-9f09-8a7d6e7f49a1',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('144efc9c-9e27-4569-ac67-c0739de6bd95',	'INS-20251202-0013',	'56774264-3dbb-4c24-83cb-e9c4b35356c9',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('6ad8b944-ca5a-4000-adcb-bdaaffe4bf05',	'INS-20251202-0014',	'b711b7b8-8dc9-46ea-b70e-787dab4f3813',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('c4369b94-8e5d-40f6-a189-f5342e1fd503',	'INS-20251202-0015',	'1ea69140-4932-406c-b5a6-86b37a6a31e5',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('8c9bc3b6-48f1-4e04-a5c5-a52e65cb6701',	'INS-20251202-0016',	'fdce7838-c916-4bf8-ae67-bea31ab9306c',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('6101a252-b9df-47a1-8ff1-3be3e6044faf',	'INS-20251202-0017',	'47aa4075-d780-4092-9bae-0903074777a5',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('6a03f822-d17b-44ac-858e-66c91b17db50',	'INS-20251202-0018',	'1ad833d5-5d45-4e70-9018-0b8ac15943e4',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('88d66729-bea0-4787-9890-8e045bf895f5',	'INS-20251202-0019',	'b134399b-f98e-48da-ae37-ef78ca6ef2aa',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('07697710-82ba-4417-a94d-5013a9b1eb6e',	'INS-20251202-0020',	'eb717701-bf90-4983-8dce-0796de17fa5f',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('50083ca5-78d3-46ce-80b4-f42315420d07',	'INS-20251202-0021',	'1a2430a1-fcee-4c25-a3db-de79d54780f2',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('ea0f1f0a-b9bf-4cc0-9e98-5836f6e43dbe',	'INS-20251202-0022',	'8411e766-ec96-4cc9-ab6d-4d3a706b4265',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('dede0e81-8366-4f1d-b87a-0e5dbde2b032',	'INS-20251202-0023',	'76af7b61-4884-4322-8496-a273ae21e803',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('7d0b2307-02e4-4d77-907b-3d7cd966514b',	'INS-20251202-0024',	'f06d4037-5a96-4486-93c1-ae2b2bc8fd7d',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('bd161f67-8149-4ed5-8134-8bbf5c56646a',	'INS-20251202-0025',	'dfd78098-8df3-44bf-82f7-a36c4688fe78',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('7eb4cccb-5bf0-44ab-b8f4-90ef1b665812',	'INS-20251202-0026',	'7881fc2e-8cc4-40c2-995f-dd8bacc86189',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('ecdabb9a-a82f-441c-a0a4-49deb6d64544',	'INS-20251202-0027',	'8dcd76f7-693d-45fb-b269-df8a0c4fa8c4',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('4f5e648a-43ce-4571-9b2f-480ff2806b2b',	'INS-20251202-0028',	'78408b7e-6f37-48b1-bccd-4f9e55f0b93a',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('972a9620-521b-4a77-aea6-f6ba37841d0c',	'INS-20251202-0029',	'bc9c8410-213d-4f6a-9f62-9de859c65e26',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('ef35ff7e-5e59-4b14-a61c-bc3a01e5e017',	'INS-20251202-0030',	'96dcd69e-47b0-4456-b576-d5972156f71b',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('da94d478-c72a-4d9e-9d21-c06da9cce4ae',	'INS-20251202-0031',	'01fae03e-fbf6-4bc4-9f2b-df20e599c20e',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('caa835ea-12c0-4a06-9bd7-1addcd2a5cdc',	'INS-20251202-0032',	'76647ce0-b7e6-4a69-b43c-86f301cec801',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	113.47,	11.35,	51.06,	51.06,	'cash',	0.00,	'completed',	'2025-12-02 17:27:07.161373',	'2025-12-02 17:27:07.161373'),
('5017c706-6ddb-466e-a797-b2a4e7e96637',	'INS-20251203-0001',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'c2909c9b-7ab1-4115-9d68-3c0006322e01',	645.50,	15.00,	90.00,	9.00,	40.50,	40.50,	'finpoint',	645.50,	'COMPLETED',	'2025-12-03 13:35:46.87711',	'2025-12-03 13:35:46.87711'),
('a9c0fa7f-cd51-4a3a-a8a7-1e386da829ea',	'INS-20251203-0002',	'ba601584-060a-4f03-8702-7abbf09353c0',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	756.50,	15.00,	105.00,	10.50,	47.25,	47.25,	'finpoint',	756.50,	'COMPLETED',	'2025-12-03 13:44:26.778393',	'2025-12-03 13:44:26.778393'),
('fdc2d088-5dba-41ce-9201-65dd7cacdb84',	'INS-20251203-0003',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'c2909c9b-7ab1-4115-9d68-3c0006322e01',	645.50,	15.00,	90.00,	9.00,	40.50,	40.50,	'finpoint',	645.50,	'COMPLETED',	'2025-12-03 13:49:45.875496',	'2025-12-03 13:49:45.875496'),
('e4a0357f-1c50-4b5a-9972-1f7015542c2a',	'INS-20251203-0004',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'e13542cb-f6d0-4853-b95f-342f5841d9b8',	4815.00,	18.00,	810.00,	81.00,	364.50,	364.50,	'finpoint',	4815.00,	'COMPLETED',	'2025-12-03 13:50:24.692465',	'2025-12-03 13:50:24.692465'),
('e6c29ea1-95a8-4a65-95dc-8c62214e1453',	'INS-20251203-0005',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'a9f48a68-1fe2-4277-ad6f-5e213b4c8d26',	12500.00,	20.00,	2400.00,	240.00,	1080.00,	1080.00,	'finpoint',	12500.00,	'COMPLETED',	'2025-12-03 13:50:42.476153',	'2025-12-03 13:50:42.476153'),
('375471ef-6033-4751-b897-1e547fd54eb4',	'INS-20251203-0006',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'bee731bb-3958-49f8-b030-21d64ecf07ef',	35000.00,	25.00,	8250.00,	825.00,	3712.50,	3712.50,	'finpoint',	35000.00,	'COMPLETED',	'2025-12-03 14:02:52.165254',	'2025-12-03 14:02:52.165254'),
('8343e2c9-4d99-4b28-b492-83ad1210e1d7',	'INS-20251204-0001',	'ba601584-060a-4f03-8702-7abbf09353c0',	'e13542cb-f6d0-4853-b95f-342f5841d9b8',	4815.00,	18.00,	810.00,	81.00,	364.50,	364.50,	'finpoint',	4815.00,	'COMPLETED',	'2025-12-04 00:23:59.128901',	'2025-12-04 00:23:59.128901'),
('c4c1e629-117f-43d6-85f5-b8648aa3e3fd',	'INS-20251204-0002',	'ba601584-060a-4f03-8702-7abbf09353c0',	'8e2d0165-7549-44e0-8b43-5f8917172905',	8500.00,	18.00,	1440.00,	144.00,	648.00,	648.00,	'finpoint',	8500.00,	'COMPLETED',	'2025-12-04 00:28:56.164728',	'2025-12-04 00:28:56.164728'),
('3855d0b7-a258-40ad-9cba-9d47ad15c928',	'INS-20251206-0001',	'00000000-0000-0000-0000-000000000000',	'c2909c9b-7ab1-4115-9d68-3c0006322e01',	645.50,	15.00,	90.00,	9.00,	40.50,	40.50,	'finpoint',	645.50,	'COMPLETED',	'2025-12-06 00:31:15.281973',	'2025-12-06 00:31:15.281973');

DROP TABLE IF EXISTS "insurance_product";
CREATE TABLE "public"."insurance_product" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "product_code" character varying(50) NOT NULL,
    "title" character varying(255) NOT NULL,
    "short_title" character varying(120),
    "description" text,
    "insurer_company_name" character varying(255) NOT NULL,
    "seller_id" uuid,
    "insurance_group" character varying(50) NOT NULL,
    "insurance_type" character varying(50) NOT NULL,
    "is_compulsory" boolean DEFAULT false NOT NULL,
    "vehicle_type" character varying(50),
    "vehicle_usage" character varying(50),
    "coverage_term_months" integer DEFAULT '12' NOT NULL,
    "sum_insured_main" numeric(15,2),
    "coverage_detail_json" jsonb,
    "currency_code" character varying(3) DEFAULT 'THB' NOT NULL,
    "premium_total" numeric(15,2) NOT NULL,
    "premium_base" numeric(15,2),
    "tax_vat_percent" numeric(5,2),
    "tax_vat_amount" numeric(15,2),
    "government_levy_amount" numeric(15,2),
    "stamp_duty_amount" numeric(15,2),
    "commission_percent" numeric(5,2),
    "commission_to_fingrow_percent" numeric(5,2) DEFAULT '10.00' NOT NULL,
    "finpoint_rate_per_100" numeric(10,2),
    "finpoint_distribution_config" jsonb,
    "fingrow_level" smallint NOT NULL,
    "cover_image_url" character varying(500),
    "brochure_url" character varying(500),
    "tags" jsonb,
    "is_active" boolean DEFAULT true NOT NULL,
    "is_featured" boolean DEFAULT false NOT NULL,
    "sort_order" integer,
    "effective_from" date,
    "effective_to" date,
    "created_at" timestamp DEFAULT now() NOT NULL,
    "updated_at" timestamp DEFAULT now() NOT NULL,
    "created_by" uuid,
    "updated_by" uuid,
    "deleted_at" timestamp,
    "finpoint_price" numeric(12,2) NOT NULL,
    "commission_pool_percent" numeric(5,2) DEFAULT '45.00' NOT NULL,
    "commission_seller_percent" numeric(5,2) DEFAULT '45.00' NOT NULL,
    "commission_amount" numeric(15,2) NOT NULL,
    "commission_fingrow_amount" numeric(15,2) NOT NULL,
    "commission_seller_amount" numeric(15,2) NOT NULL,
    "commission_pool_amount" numeric(15,2) NOT NULL,
    CONSTRAINT "insurance_product_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "chk_fingrow_level" CHECK (((fingrow_level >= 1) AND (fingrow_level <= 4))),
    CONSTRAINT "check_commission_total" CHECK ((((commission_to_fingrow_percent + commission_pool_percent) + commission_seller_percent) = 100.00))
)
WITH (oids = false);

COMMENT ON TABLE "public"."insurance_product" IS 'ตารางเก็บข้อมูลผลิตภัณฑ์ประกันภัยสำหรับ Fingrow Platform';

COMMENT ON COLUMN "public"."insurance_product"."product_code" IS 'รหัสผลิตภัณฑ์ประกัน';

COMMENT ON COLUMN "public"."insurance_product"."commission_to_fingrow_percent" IS 'เปอร์เซ็นต์ค่าคอมมิชชันที่ Fingrow Platform จะได้รับ (Management Fee) - Default 10%';

COMMENT ON COLUMN "public"."insurance_product"."finpoint_rate_per_100" IS 'จำนวน FinPoint ต่อเบี้ยประกัน 100 บาท';

COMMENT ON COLUMN "public"."insurance_product"."finpoint_distribution_config" IS 'การกระจาย FinPoint แต่ละชั้น (ACF 7 levels)';

COMMENT ON COLUMN "public"."insurance_product"."fingrow_level" IS 'ระดับ Fingrow Level (1-4) สำหรับ UI Dashboard';

COMMENT ON COLUMN "public"."insurance_product"."finpoint_price" IS 'ราคาสินค้าเป็น Finpoint (1 FP = 1 บาท ในปัจจุบัน)';

COMMENT ON COLUMN "public"."insurance_product"."commission_pool_percent" IS 'เปอร์เซ็นต์ของค่าคอมมิชชันที่จะเข้า Commission Pool (แบ่งให้ Network 7 คน) - Default 45%';

COMMENT ON COLUMN "public"."insurance_product"."commission_seller_percent" IS 'เปอร์เซ็นต์ของค่าคอมมิชชันที่ Seller (ผู้ซื้อ) จะได้รับ - Default 45%';

COMMENT ON COLUMN "public"."insurance_product"."commission_amount" IS 'ค่าคอมมิชชันรวม (บาท) คำนวณจาก premium_base × commission_percent / 100';

COMMENT ON COLUMN "public"."insurance_product"."commission_fingrow_amount" IS 'ค่าคอมมิชชันส่วน Fingrow Platform (10% ของ commission_amount)';

COMMENT ON COLUMN "public"."insurance_product"."commission_seller_amount" IS 'ค่าคอมมิชชันส่วน Seller (45% ของ commission_amount)';

COMMENT ON COLUMN "public"."insurance_product"."commission_pool_amount" IS 'ค่าคอมมิชชันส่วน Pool แบ่ง 7 คน (45% ของ commission_amount)';

CREATE INDEX idx_insurance_product_insurance_group ON public.insurance_product USING btree (insurance_group);

CREATE INDEX idx_insurance_product_insurance_type ON public.insurance_product USING btree (insurance_type);

CREATE INDEX idx_insurance_product_is_active ON public.insurance_product USING btree (is_active);

CREATE INDEX idx_insurance_product_insurer_company_name ON public.insurance_product USING btree (insurer_company_name);

CREATE INDEX idx_insurance_product_fingrow_level ON public.insurance_product USING btree (fingrow_level);

CREATE INDEX idx_insurance_product_tags ON public.insurance_product USING gin (tags);

CREATE INDEX idx_insurance_product_coverage_detail_json ON public.insurance_product USING gin (coverage_detail_json);

CREATE INDEX idx_insurance_product_finpoint_distribution_config ON public.insurance_product USING gin (finpoint_distribution_config);

INSERT INTO "insurance_product" ("id", "product_code", "title", "short_title", "description", "insurer_company_name", "seller_id", "insurance_group", "insurance_type", "is_compulsory", "vehicle_type", "vehicle_usage", "coverage_term_months", "sum_insured_main", "coverage_detail_json", "currency_code", "premium_total", "premium_base", "tax_vat_percent", "tax_vat_amount", "government_levy_amount", "stamp_duty_amount", "commission_percent", "commission_to_fingrow_percent", "finpoint_rate_per_100", "finpoint_distribution_config", "fingrow_level", "cover_image_url", "brochure_url", "tags", "is_active", "is_featured", "sort_order", "effective_from", "effective_to", "created_at", "updated_at", "created_by", "updated_by", "deleted_at", "finpoint_price", "commission_pool_percent", "commission_seller_percent", "commission_amount", "commission_fingrow_amount", "commission_seller_amount", "commission_pool_amount") VALUES
('c2909c9b-7ab1-4115-9d68-3c0006322e01',	'PRB-MOTO-2025-001',	'พรบ. รถจักรยานยนต์ ความคุ้มครอง 50,000 บาท',	'พรบ. มอเตอร์ไซค์',	'ประกันภาคบังคับรถจักรยานยนต์ คุ้มครองผู้ประสบภัยจากรถ วงเงิน 50,000 บาท ตามกฎหมาย',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'motor',	'PRB',	'1',	'motorcycle',	'personal',	12,	50000.00,	NULL,	'THB',	645.50,	600.00,	7.00,	42.00,	NULL,	3.50,	15.00,	10.00,	2.50,	'{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 15}',	1,	NULL,	NULL,	'["popular", "compulsory", "level1", "motorcycle"]',	'1',	'1',	10,	NULL,	NULL,	'2025-12-02 00:36:22.09171',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	645.50,	45.00,	45.00,	90.00,	9.00,	40.50,	40.50),
('8e2d0165-7549-44e0-8b43-5f8917172905',	'HEALTH-IND-2025-001',	'ประกันสุขภาพรายบุคคล แผนพื้นฐาน',	'ประกันสุขภาพ แผนพื้นฐาน',	'ประกันสุขภาพรายบุคคล คุ้มครองค่ารักษาพยาบาล ค่าห้องและค่าอาหาร วงเงิน 500,000 บาท/ปี',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'health',	'INDIVIDUAL_HEALTH',	'0',	NULL,	NULL,	12,	500000.00,	NULL,	'THB',	8500.00,	8000.00,	7.00,	560.00,	NULL,	NULL,	18.00,	10.00,	5.00,	'{"levels": [35, 20, 15, 12, 8, 6, 4], "self_bonus": 20}',	3,	NULL,	NULL,	'["popular", "health", "level3", "individual"]',	'1',	'1',	10,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	8500.00,	45.00,	45.00,	1440.00,	144.00,	648.00,	648.00),
('79110fb1-8db0-479c-b920-224b8eb3fc0a',	'HEALTH-FAM-2025-001',	'ประกันสุขภาพครอบครัว แผนครอบครัว',	'ประกันสุขภาพ ครอบครัว',	'ประกันสุขภาพครอบครัว คุ้มครอง 4 คน ค่ารักษาพยาบาล ค่าห้องและค่าอาหาร วงเงิน 1,000,000 บาท/ปี',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'health',	'FAMILY_HEALTH',	'0',	NULL,	NULL,	12,	1000000.00,	NULL,	'THB',	15800.00,	15000.00,	7.00,	1050.00,	NULL,	NULL,	18.00,	10.00,	6.00,	'{"levels": [35, 20, 15, 12, 8, 6, 4], "self_bonus": 20}',	3,	NULL,	NULL,	'["popular", "health", "level3", "family"]',	'1',	'1',	20,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	15800.00,	45.00,	45.00,	2700.00,	270.00,	1215.00,	1215.00),
('a9f48a68-1fe2-4277-ad6f-5e213b4c8d26',	'HEALTH-CANCER-2025-001',	'ประกันโรคร้ายแรง (มะเร็ง)',	'ประกันโรคมะเร็ง',	'ประกันโรคร้ายแรง คุ้มครองโรคมะเร็ง จ่ายเงินก้อน 1,000,000 บาท เมื่อวินิจฉัยเป็นมะเร็ง',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'health',	'CRITICAL_ILLNESS',	'0',	NULL,	NULL,	12,	1000000.00,	NULL,	'THB',	12500.00,	12000.00,	7.00,	840.00,	NULL,	NULL,	20.00,	10.00,	5.50,	'{"levels": [35, 20, 15, 12, 8, 6, 4], "self_bonus": 20}',	3,	NULL,	NULL,	'["health", "level3", "critical-illness", "cancer"]',	'1',	'0',	30,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	12500.00,	45.00,	45.00,	2400.00,	240.00,	1080.00,	1080.00),
('bee731bb-3958-49f8-b030-21d64ecf07ef',	'LIFE-TERM-2025-001',	'ประกันชีวิตแบบสะสมทรัพย์ 10 ปี',	'ประกันชีวิต 10 ปี',	'ประกันชีวิตแบบสะสมทรัพย์ ระยะเวลา 10 ปี ทุนประกัน 1,000,000 บาท พร้อมเงินคืนเมื่อครบกำหนด',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'life',	'ENDOWMENT',	'0',	NULL,	NULL,	120,	1000000.00,	NULL,	'THB',	35000.00,	33000.00,	7.00,	2310.00,	NULL,	NULL,	25.00,	10.00,	8.00,	'{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',	4,	NULL,	NULL,	'["popular", "life", "level4", "endowment", "savings"]',	'1',	'1',	10,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	35000.00,	45.00,	45.00,	8250.00,	825.00,	3712.50,	3712.50),
('ba36a892-fc97-4583-bed4-9acaffb7b083',	'PRB-CAR-2025-001',	'พรบ. รถยนต์นั่งส่วนบุคคล ไม่เกิน 7 ที่นั่ง',	'พรบ. รถยนต์',	'ประกันภาคบังคับรถยนต์ คุ้มครองผู้ประสบภัยจากรถ ความรับผิดชอบตามกฎหมาย',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'motor',	'PRB',	'1',	'car',	'personal',	12,	100000.00,	NULL,	'THB',	756.50,	700.00,	7.00,	49.00,	NULL,	7.50,	15.00,	10.00,	3.00,	'{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 15}',	1,	NULL,	NULL,	'["popular", "compulsory", "level1", "car"]',	'1',	'1',	20,	NULL,	NULL,	'2025-12-02 00:36:22.09171',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	756.50,	45.00,	45.00,	105.00,	10.50,	47.25,	47.25),
('704f0b52-dd40-467d-93eb-d79820f479e5',	'LIFE-WHOLE-2025-001',	'ประกันชีวิตตลอดชีพ พรีเมียม',	'ประกันชีวิต ตลอดชีพ',	'ประกันชีวิตตลอดชีพ ทุนประกัน 2,000,000 บาท คุ้มครองตลอดชีพ มูลค่าเงินสดสะสม',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'life',	'WHOLE_LIFE',	'0',	NULL,	NULL,	12,	2000000.00,	NULL,	'THB',	58000.00,	55000.00,	7.00,	3850.00,	NULL,	NULL,	25.00,	10.00,	10.00,	'{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',	4,	NULL,	NULL,	'["life", "level4", "whole-life", "premium"]',	'1',	'1',	20,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	58000.00,	45.00,	45.00,	13750.00,	1375.00,	6187.50,	6187.50),
('e13542cb-f6d0-4853-b95f-342f5841d9b8',	'CAR-3PLUS-2025-001',	'ประกันภัยรถยนต์ ชั้น 3+ คุ้มครองครบ รวมอุบัติเหตุส่วนบุคคล',	'รถยนต์ ชั้น 3+',	'คุ้มครองความเสียหายต่อบุคคลภายนอก + ไฟไหม้ รถหาย + อุบัติเหตุส่วนบุคคลผู้ขับขี่ 100,000 บาท',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'motor',	'CAR_3PLUS',	'0',	'car',	'personal',	12,	1000000.00,	'{"fire_theft": "covered", "medical_expense": 20000, "third_party_body": 1000000, "third_party_property": 1000000, "personal_accident_driver": 100000}',	'THB',	4815.00,	4500.00,	7.00,	315.00,	NULL,	0.00,	18.00,	10.00,	4.00,	'{"levels": [35, 25, 15, 10, 7, 5, 3], "self_bonus": 20}',	2,	NULL,	NULL,	'["popular", "level2", "car", "fire-theft"]',	'1',	'1',	30,	NULL,	NULL,	'2025-12-02 00:36:22.09171',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	4815.00,	45.00,	45.00,	810.00,	81.00,	364.50,	364.50),
('ad0977d1-7fa7-47f7-b468-eb08c2eedd6d',	'CAR-3PLUS-2025-002',	'ประกันภัยรถยนต์ ชั้น 3+ Platinum คุ้มครองเพิ่ม อุบัติเหตุคนขับ 500,000',	'รถยนต์ 3+ Platinum',	'คุ้มครองบุคคลภายนอก + ไฟไหม้ รถหาย + อุบัติเหตุส่วนบุคคล 500,000 บาท + ค่ารักษาพยาบาล',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'motor',	'CAR_3PLUS',	'0',	'car',	'personal',	12,	1000000.00,	'{"bail_bond": 200000, "fire_theft": "covered", "medical_expense": 50000, "third_party_body": 1000000, "third_party_property": 1000000, "personal_accident_driver": 500000}',	'THB',	6960.50,	6505.00,	7.00,	455.50,	NULL,	NULL,	20.00,	10.00,	4.50,	'{"levels": [35, 25, 15, 10, 7, 5, 3], "self_bonus": 20}',	2,	NULL,	NULL,	'["level2", "car", "premium", "high-coverage"]',	'1',	'0',	40,	NULL,	NULL,	'2025-12-02 00:36:22.09171',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	6960.50,	45.00,	45.00,	1301.00,	130.10,	585.45,	585.45),
('cad719c0-fe7b-46ba-b213-e831f2542746',	'LIFE-INVEST-2025-001',	'ประกันชีวิตควบการลงทุน (Unit Link)',	'Unit Link ชีวิต+ลงทุน',	'ประกันชีวิตควบการลงทุน ทุนประกัน 3,000,000 บาท พร้อมกองทุนลงทุนหลากหลาย',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'life',	'UNIT_LINKED',	'0',	NULL,	NULL,	12,	3000000.00,	NULL,	'THB',	72000.00,	68000.00,	7.00,	4760.00,	NULL,	NULL,	28.00,	10.00,	12.00,	'{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',	4,	NULL,	NULL,	'["life", "level4", "unit-linked", "investment", "premium"]',	'1',	'1',	30,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	72000.00,	45.00,	45.00,	19040.00,	1904.00,	8568.00,	8568.00),
('32b554d5-64ff-46cc-b3a1-ead807a5dc9d',	'LIFE-RETIRE-2025-001',	'ประกันบำนาญ เพื่อการเกษียณ',	'ประกันบำนาญ',	'ประกันบำนาญ เริ่มรับเงินบำนาญอายุ 60 ปี 20,000 บาท/เดือน ตลอดชีพ',	'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด',	NULL,	'life',	'ANNUITY',	'0',	NULL,	NULL,	12,	5000000.00,	NULL,	'THB',	95000.00,	90000.00,	7.00,	6300.00,	NULL,	NULL,	28.00,	10.00,	15.00,	'{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',	4,	NULL,	NULL,	'["life", "level4", "annuity", "retirement", "vip"]',	'1',	'0',	40,	NULL,	NULL,	'2025-12-02 01:07:48.239005',	'2025-12-03 01:04:09.260343',	NULL,	NULL,	NULL,	95000.00,	45.00,	45.00,	25200.00,	2520.00,	11340.00,	11340.00);

DELIMITER ;;

CREATE TRIGGER "trigger_insurance_product_updated_at" BEFORE UPDATE ON "public"."insurance_product" FOR EACH ROW EXECUTE FUNCTION update_insurance_product_updated_at();;

DELIMITER ;

DROP TABLE IF EXISTS "messages";
CREATE TABLE "public"."messages" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "chat_room_id" uuid NOT NULL,
    "sender_id" uuid NOT NULL,
    "message_type" character varying(50) DEFAULT 'text',
    "content" text,
    "images" jsonb,
    "offer_amount" numeric(15,2),
    "offer_currency" character varying(3),
    "offer_expires_at" timestamp,
    "is_read" boolean DEFAULT false,
    "read_at" timestamp,
    "is_deleted" boolean DEFAULT false,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_messages_chat_room_id ON public.messages USING btree (chat_room_id);

CREATE INDEX idx_messages_sender_id ON public.messages USING btree (sender_id);

CREATE INDEX idx_messages_created_at ON public.messages USING btree (created_at);


DROP TABLE IF EXISTS "notifications";
CREATE TABLE "public"."notifications" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "type" character varying(50) NOT NULL,
    "title" character varying(255) NOT NULL,
    "body" text NOT NULL,
    "data" jsonb,
    "is_read" boolean DEFAULT false,
    "read_at" timestamp,
    "push_sent" boolean DEFAULT false,
    "push_sent_at" timestamp,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);

CREATE INDEX idx_notifications_type ON public.notifications USING btree (type);

CREATE INDEX idx_notifications_is_read ON public.notifications USING btree (is_read) WHERE (is_read = false);


DROP TABLE IF EXISTS "order_items";
CREATE TABLE "public"."order_items" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "order_id" uuid NOT NULL,
    "product_id" uuid NOT NULL,
    "quantity" integer DEFAULT '1',
    "unit_price" numeric(15,2) NOT NULL,
    "total_price" numeric(15,2) NOT NULL,
    "product_title" character varying(500),
    "product_condition" character varying(50),
    "product_image" text,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_order_items_order_id ON public.order_items USING btree (order_id);

CREATE INDEX idx_order_items_product_id ON public.order_items USING btree (product_id);


DROP TABLE IF EXISTS "orders";
CREATE TABLE "public"."orders" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "order_number" character varying(50),
    "buyer_id" uuid NOT NULL,
    "seller_id" uuid NOT NULL,
    "product_id" uuid,
    "quantity" integer DEFAULT '1',
    "subtotal" numeric(15,2) DEFAULT '0',
    "shipping_cost" numeric(15,2) DEFAULT '0',
    "tax_amount" numeric(15,2) DEFAULT '0',
    "community_fee" numeric(15,2) DEFAULT '0',
    "total_amount" numeric(15,2) DEFAULT '0',
    "total_price_wld" numeric(15,8) DEFAULT '0',
    "total_price_local" numeric(15,2) DEFAULT '0',
    "currency_code" character varying(3) DEFAULT 'THB',
    "wld_rate" numeric(15,8) DEFAULT '0',
    "total_wld" numeric(15,8) DEFAULT '0',
    "shipping_address" jsonb,
    "shipping_method" character varying(100),
    "tracking_number" character varying(100),
    "notes" text,
    "buyer_notes" text,
    "seller_notes" text,
    "admin_notes" text,
    "status" character varying(50) DEFAULT 'pending',
    "payment_status" character varying(50) DEFAULT 'pending',
    "order_date" timestamp DEFAULT now(),
    "confirmed_at" timestamp,
    "shipped_at" timestamp,
    "delivered_at" timestamp,
    "completed_at" timestamp,
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX orders_order_number_key ON public.orders USING btree (order_number);

CREATE INDEX idx_orders_buyer_id ON public.orders USING btree (buyer_id);

CREATE INDEX idx_orders_seller_id ON public.orders USING btree (seller_id);

CREATE INDEX idx_orders_status ON public.orders USING btree (status);

CREATE INDEX idx_orders_payment_status ON public.orders USING btree (payment_status);

CREATE INDEX idx_orders_order_date ON public.orders USING btree (order_date);


DELIMITER ;;

CREATE TRIGGER "update_orders_updated_at" BEFORE UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP TABLE IF EXISTS "payment_methods";
CREATE TABLE "public"."payment_methods" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "type" character varying(50) NOT NULL,
    "provider" character varying(100),
    "account_details" jsonb,
    "display_name" character varying(255),
    "is_verified" boolean DEFAULT false,
    "is_default" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_payment_methods_user_id ON public.payment_methods USING btree (user_id);


DELIMITER ;;

CREATE TRIGGER "update_payment_methods_updated_at" BEFORE UPDATE ON "public"."payment_methods" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP TABLE IF EXISTS "product_images";
CREATE TABLE "public"."product_images" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "product_id" uuid NOT NULL,
    "image_url" text NOT NULL,
    "is_primary" boolean DEFAULT false,
    "sort_order" integer DEFAULT '0',
    "alt_text" character varying(500),
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "product_images_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_product_images_product_id ON public.product_images USING btree (product_id);


DROP TABLE IF EXISTS "products";
CREATE TABLE "public"."products" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "seller_id" uuid NOT NULL,
    "category" character varying(100),
    "category_id" uuid,
    "title" character varying(500) NOT NULL,
    "description" text,
    "condition" character varying(50),
    "price_wld" numeric(15,8),
    "price_local" numeric(15,2) NOT NULL,
    "original_price" numeric(15,2),
    "currency_code" character varying(3) DEFAULT 'THB',
    "location" jsonb,
    "shipping_options" jsonb,
    "pickup_available" boolean DEFAULT false,
    "brand" character varying(255),
    "model" character varying(255),
    "year_purchased" integer,
    "warranty_remaining" integer,
    "included_accessories" jsonb,
    "images" jsonb,
    "videos" jsonb,
    "quantity" integer DEFAULT '1',
    "is_available" boolean DEFAULT true,
    "is_featured" boolean DEFAULT false,
    "featured_until" timestamp,
    "community_percentage" numeric(5,2) DEFAULT '2.0',
    "amount_fee" numeric(15,2) DEFAULT '0.0',
    "view_count" integer DEFAULT '0',
    "favorite_count" integer DEFAULT '0',
    "inquiry_count" integer DEFAULT '0',
    "status" character varying(50) DEFAULT 'active',
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "products_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "products_price_local_check" CHECK ((price_local >= (0)::numeric)),
    CONSTRAINT "products_quantity_check" CHECK ((quantity >= 0)),
    CONSTRAINT "products_community_percentage_check" CHECK (((community_percentage >= (0)::numeric) AND (community_percentage <= (100)::numeric)))
)
WITH (oids = false);

CREATE INDEX idx_products_seller_id ON public.products USING btree (seller_id);

CREATE INDEX idx_products_category ON public.products USING btree (category);

CREATE INDEX idx_products_status ON public.products USING btree (status);

CREATE INDEX idx_products_is_available ON public.products USING btree (is_available) WHERE (is_available = true);

CREATE INDEX idx_products_created_at ON public.products USING btree (created_at);


DELIMITER ;;

CREATE TRIGGER "update_products_updated_at" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP TABLE IF EXISTS "referrals";
CREATE TABLE "public"."referrals" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "referrer_id" uuid NOT NULL,
    "referee_id" uuid NOT NULL,
    "level" integer NOT NULL,
    "first_purchase_made" boolean DEFAULT false,
    "first_purchase_date" timestamp,
    "total_purchases_made" integer DEFAULT '0',
    "total_purchase_value" numeric(15,2) DEFAULT '0',
    "total_commission_earned" numeric(15,2) DEFAULT '0',
    "last_commission_date" timestamp,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "referrals_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "referrals_level_check" CHECK (((level >= 1) AND (level <= 7)))
)
WITH (oids = false);

CREATE INDEX idx_referrals_referrer_id ON public.referrals USING btree (referrer_id);

CREATE INDEX idx_referrals_referee_id ON public.referrals USING btree (referee_id);

CREATE INDEX idx_referrals_level ON public.referrals USING btree (level);


DROP TABLE IF EXISTS "reviews";
CREATE TABLE "public"."reviews" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "order_id" uuid NOT NULL,
    "product_id" uuid NOT NULL,
    "buyer_id" uuid NOT NULL,
    "seller_id" uuid NOT NULL,
    "reviewer_id" uuid,
    "reviewed_user_id" uuid,
    "rating" integer NOT NULL,
    "title" character varying(255),
    "comment" text NOT NULL,
    "images" jsonb,
    "communication_rating" integer,
    "item_quality_rating" integer,
    "shipping_rating" integer,
    "is_verified_purchase" boolean DEFAULT true,
    "is_visible" boolean DEFAULT true,
    "seller_response" text,
    "seller_response_date" timestamp,
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "reviews_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "reviews_rating_check" CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT "reviews_communication_rating_check" CHECK (((communication_rating IS NULL) OR ((communication_rating >= 1) AND (communication_rating <= 5)))),
    CONSTRAINT "reviews_item_quality_rating_check" CHECK (((item_quality_rating IS NULL) OR ((item_quality_rating >= 1) AND (item_quality_rating <= 5)))),
    CONSTRAINT "reviews_shipping_rating_check" CHECK (((shipping_rating IS NULL) OR ((shipping_rating >= 1) AND (shipping_rating <= 5))))
)
WITH (oids = false);

CREATE INDEX idx_reviews_product_id ON public.reviews USING btree (product_id);

CREATE INDEX idx_reviews_buyer_id ON public.reviews USING btree (buyer_id);

CREATE INDEX idx_reviews_seller_id ON public.reviews USING btree (seller_id);

CREATE INDEX idx_reviews_rating ON public.reviews USING btree (rating);


DELIMITER ;;

CREATE TRIGGER "update_reviews_updated_at" BEFORE UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP TABLE IF EXISTS "settings";
CREATE TABLE "public"."settings" (
    "key" character varying(255) NOT NULL,
    "value" text,
    "description" text,
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "settings_pkey" PRIMARY KEY ("key")
)
WITH (oids = false);


DROP TABLE IF EXISTS "simulated_fp_ledger";
CREATE TABLE "public"."simulated_fp_ledger" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "simulated_tx_id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "related_user_id" uuid,
    "level" integer,
    "simulated_entry_role" character varying(50),
    "dr_cr" character varying(2) NOT NULL,
    "simulated_fp_amount" numeric(15,2) NOT NULL,
    "simulated_balance_after" numeric(15,2),
    "simulated_tx_type" character varying(50) NOT NULL,
    "simulated_source_type" character varying(100),
    "simulated_source_id" character varying(255),
    "simulated_tx_datetime" timestamp,
    "simulated_tx_year" integer,
    "simulated_tx_month" integer,
    "simulated_tx_day" integer,
    "created_at" timestamp DEFAULT now(),
    CONSTRAINT "simulated_fp_ledger_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "simulated_fp_ledger_dr_cr_check" CHECK (((dr_cr)::text = ANY ((ARRAY['DR'::character varying, 'CR'::character varying])::text[]))),
    CONSTRAINT "simulated_fp_ledger_simulated_fp_amount_check" CHECK ((simulated_fp_amount >= (0)::numeric)),
    CONSTRAINT "simulated_fp_ledger_level_check" CHECK (((level IS NULL) OR ((level >= 0) AND (level <= 6))))
)
WITH (oids = false);

CREATE INDEX idx_simulated_fp_ledger_tx_id ON public.simulated_fp_ledger USING btree (simulated_tx_id);

CREATE INDEX idx_simulated_fp_ledger_user_id ON public.simulated_fp_ledger USING btree (user_id);

CREATE INDEX idx_simulated_fp_ledger_tx_type ON public.simulated_fp_ledger USING btree (simulated_tx_type);

CREATE INDEX idx_simulated_fp_ledger_dr_cr ON public.simulated_fp_ledger USING btree (dr_cr);

CREATE INDEX idx_simulated_fp_ledger_tx_datetime ON public.simulated_fp_ledger USING btree (simulated_tx_datetime);

CREATE INDEX idx_simulated_fp_ledger_year_month ON public.simulated_fp_ledger USING btree (simulated_tx_year, simulated_tx_month);

INSERT INTO "simulated_fp_ledger" ("id", "simulated_tx_id", "user_id", "related_user_id", "level", "simulated_entry_role", "dr_cr", "simulated_fp_amount", "simulated_balance_after", "simulated_tx_type", "simulated_source_type", "simulated_source_id", "simulated_tx_datetime", "simulated_tx_year", "simulated_tx_month", "simulated_tx_day", "created_at") VALUES
('e2f55c3f-c535-473c-a8da-6b0c96505401',	'7a44bdf8-28be-4450-9657-72447956947a',	'ba601584-060a-4f03-8702-7abbf09353c0',	NULL,	NULL,	NULL,	'DR',	45.00,	45.00,	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	'2025-11-28 05:35:50.753733',	NULL,	NULL,	NULL,	'2025-11-28 05:35:50.753733'),
('19dcbf3e-d78e-410b-bde1-e99a09cb36cd',	'c83a94b5-c91f-42fa-98be-e4db081a6cc9',	'ba601584-060a-4f03-8702-7abbf09353c0',	NULL,	NULL,	NULL,	'DR',	50.00,	95.00,	'NETWORK_BONUS',	'network_bonus',	NULL,	'2025-11-29 05:35:50.753733',	NULL,	NULL,	NULL,	'2025-11-29 05:35:50.753733'),
('3603aac8-b8d0-4701-b1c3-6e9989779621',	'bc6b2474-39cc-4660-b430-93b41ca82a59',	'ba601584-060a-4f03-8702-7abbf09353c0',	NULL,	NULL,	NULL,	'CR',	600.00,	-505.00,	'INSURANCE_PURCHASE',	'insurance_LEVEL_1',	NULL,	'2025-11-30 02:35:50.753733',	NULL,	NULL,	NULL,	'2025-11-30 02:35:50.753733'),
('06335004-8001-478c-ae18-28bf9cd0a635',	'53138259-0e8a-4750-b1cc-a5f020a86575',	'9350d0b2-5d70-4105-82ac-13021a62b868',	NULL,	NULL,	NULL,	'DR',	36.00,	36.00,	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	'2025-11-29 10:22:01.58522',	NULL,	NULL,	NULL,	'2025-11-29 10:22:01.58522'),
('9b9efc9d-4da4-4562-9a67-37578fb30937',	'a749287e-98c2-4c44-a506-2b164dcbae97',	'9350d0b2-5d70-4105-82ac-13021a62b868',	NULL,	NULL,	NULL,	'DR',	0.00,	66.00,	'NETWORK_BONUS',	'network_bonus',	NULL,	'2025-11-30 05:22:01.58522',	NULL,	NULL,	NULL,	'2025-11-30 05:22:01.58522');

DROP TABLE IF EXISTS "simulated_fp_transactions";
CREATE TABLE "public"."simulated_fp_transactions" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "simulated_tx_type" character varying(50) NOT NULL,
    "simulated_source_type" character varying(100) NOT NULL,
    "simulated_source_id" character varying(255),
    "simulated_base_amount" numeric(15,2) NOT NULL,
    "simulated_reverse_rate" numeric(5,4) NOT NULL,
    "simulated_generated_fp" numeric(15,2) NOT NULL,
    "simulated_system_cut_rate" numeric(5,2) DEFAULT '0.10',
    "simulated_system_cut_fp" numeric(15,2) DEFAULT '0.0',
    "simulated_self_rate" numeric(5,2) DEFAULT '0.45',
    "simulated_self_fp" numeric(15,2) DEFAULT '0.0',
    "simulated_network_rate" numeric(5,2) DEFAULT '0.45',
    "simulated_network_fp" numeric(15,2) DEFAULT '0.0',
    "simulated_upline_depth" integer DEFAULT '7',
    "simulated_status" character varying(50) DEFAULT 'PENDING' NOT NULL,
    "simulated_error_message" text,
    "simulated_run_mode" character varying(50) DEFAULT 'AUTO',
    "created_at" timestamp DEFAULT now(),
    "updated_at" timestamp DEFAULT now(),
    CONSTRAINT "simulated_fp_transactions_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "simulated_fp_transactions_simulated_base_amount_check" CHECK ((simulated_base_amount >= (0)::numeric)),
    CONSTRAINT "simulated_fp_transactions_simulated_reverse_rate_check" CHECK ((simulated_reverse_rate >= (0)::numeric)),
    CONSTRAINT "simulated_fp_transactions_simulated_upline_depth_check" CHECK (((simulated_upline_depth >= 1) AND (simulated_upline_depth <= 7)))
)
WITH (oids = false);

CREATE INDEX idx_simulated_fp_transactions_user_id ON public.simulated_fp_transactions USING btree (user_id);

CREATE INDEX idx_simulated_fp_transactions_tx_type ON public.simulated_fp_transactions USING btree (simulated_tx_type);

CREATE INDEX idx_simulated_fp_transactions_status ON public.simulated_fp_transactions USING btree (simulated_status);

CREATE INDEX idx_simulated_fp_transactions_created_at ON public.simulated_fp_transactions USING btree (created_at);

INSERT INTO "simulated_fp_transactions" ("id", "user_id", "simulated_tx_type", "simulated_source_type", "simulated_source_id", "simulated_base_amount", "simulated_reverse_rate", "simulated_generated_fp", "simulated_system_cut_rate", "simulated_system_cut_fp", "simulated_self_rate", "simulated_self_fp", "simulated_network_rate", "simulated_network_fp", "simulated_upline_depth", "simulated_status", "simulated_error_message", "simulated_run_mode", "created_at", "updated_at") VALUES
('7a44bdf8-28be-4450-9657-72447956947a',	'ba601584-060a-4f03-8702-7abbf09353c0',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1000.00,	0.1000,	100.00,	0.10,	0.00,	0.45,	45.00,	0.45,	45.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 05:35:50.753733',	'2025-11-30 05:35:50.753733'),
('c83a94b5-c91f-42fa-98be-e4db081a6cc9',	'ba601584-060a-4f03-8702-7abbf09353c0',	'NETWORK_BONUS',	'network_bonus',	NULL,	500.00,	0.1000,	50.00,	0.10,	0.00,	0.45,	0.00,	0.45,	50.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 05:35:50.753733',	'2025-11-30 05:35:50.753733'),
('bc6b2474-39cc-4660-b430-93b41ca82a59',	'ba601584-060a-4f03-8702-7abbf09353c0',	'INSURANCE_PURCHASE',	'insurance_LEVEL_1',	NULL,	600.00,	1.0000,	600.00,	0.10,	0.00,	0.45,	0.00,	0.45,	0.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 02:35:50.753733',	'2025-11-30 05:35:50.753733'),
('53138259-0e8a-4750-b1cc-a5f020a86575',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	800.00,	0.1000,	80.00,	0.10,	0.00,	0.45,	36.00,	0.45,	36.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 10:22:01.58522',	'2025-11-30 10:22:01.58522'),
('a749287e-98c2-4c44-a506-2b164dcbae97',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'NETWORK_BONUS',	'network_bonus',	NULL,	300.00,	0.1000,	30.00,	0.10,	0.00,	0.45,	0.00,	0.45,	30.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 05:22:01.58522',	'2025-11-30 10:22:01.58522'),
('0194281e-de5d-4600-92ec-1bc1a8c2490b',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1200.00,	0.1000,	120.00,	0.10,	0.00,	0.45,	54.00,	0.45,	54.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 17:34:06.964907',	'2025-11-30 17:34:06.964907'),
('75a3504e-ea28-4656-af28-cf91ef40c57f',	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	'NETWORK_BONUS',	'network_bonus',	NULL,	400.00,	0.1000,	40.00,	0.10,	0.00,	0.45,	0.00,	0.45,	40.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 17:34:06.964907',	'2025-11-30 17:34:06.964907'),
('053b6ab1-6c73-48e8-bc81-9737a6290cab',	'b86923e4-ae78-4dad-a5d1-070f72006c83',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	900.00,	0.1000,	90.00,	0.10,	0.00,	0.45,	40.50,	0.45,	40.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-27 17:34:06.964907',	'2025-11-30 17:34:06.964907'),
('f8a389f7-4028-45ee-8c27-c6c19e3e8716',	'b86923e4-ae78-4dad-a5d1-070f72006c83',	'NETWORK_BONUS',	'network_bonus',	NULL,	350.00,	0.1000,	35.00,	0.10,	0.00,	0.45,	0.00,	0.45,	35.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 11:34:06.964907',	'2025-11-30 17:34:06.964907'),
('deed8abc-58a8-439e-9474-336122871440',	'aeaba876-100a-4da3-ae90-ae175bfdd5aa',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1500.00,	0.1000,	150.00,	0.10,	0.00,	0.45,	67.50,	0.45,	67.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-26 17:34:06.964907',	'2025-11-30 17:34:06.964907'),
('d4ba93f2-50a5-4cec-ae77-e48a512ffc3f',	'aeaba876-100a-4da3-ae90-ae175bfdd5aa',	'INSURANCE_PURCHASE',	'insurance_LEVEL_1',	NULL,	600.00,	1.0000,	600.00,	0.10,	0.00,	0.45,	0.00,	0.45,	0.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 15:34:06.964907',	'2025-11-30 17:34:06.964907'),
('3ade903a-9bf9-41e8-adf8-257541f4f36f',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1000.00,	0.1000,	100.00,	0.10,	0.00,	0.45,	45.00,	0.45,	45.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 23:56:26.895544',	'2025-11-30 23:56:26.895544'),
('c9c3b48a-16d1-4993-ab49-3ab1c8b4d741',	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'NETWORK_BONUS',	'network_bonus',	NULL,	300.00,	0.1000,	30.00,	0.10,	0.00,	0.45,	0.00,	0.45,	30.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 15:56:26.895544',	'2025-11-30 23:56:26.895544'),
('a462eb94-9f70-44ec-b5f1-bba2fc6de573',	'78e83bc3-7fc2-4528-9909-8154b641fc08',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	900.00,	0.1000,	90.00,	0.10,	0.00,	0.45,	40.50,	0.45,	40.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-27 23:56:31.672463',	'2025-11-30 23:56:31.672463'),
('67e6bf50-7cf9-4b28-a30a-04968ffe12e2',	'd77ef8b3-df9f-48b7-8eed-485a0a592abd',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1300.00,	0.1000,	130.00,	0.10,	0.00,	0.45,	58.50,	0.45,	58.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 23:56:31.672463',	'2025-11-30 23:56:31.672463'),
('331e5fa1-806c-436d-8fc4-360d1e5bab81',	'7b8b9dc4-4e6a-4c99-8988-6c176e2904c2',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1100.00,	0.1000,	110.00,	0.10,	0.00,	0.45,	49.50,	0.45,	49.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-26 23:56:31.672463',	'2025-11-30 23:56:31.672463'),
('2c475d16-1d9b-4866-9f93-dc3058881ebd',	'ee579d17-2a8f-46df-9f09-8a7d6e7f49a1',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1500.00,	0.1000,	150.00,	0.10,	0.00,	0.45,	67.50,	0.45,	67.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 23:56:31.672463',	'2025-11-30 23:56:31.672463'),
('7f5ffeb0-7180-481f-9ab7-e996d67892fb',	'ee579d17-2a8f-46df-9f09-8a7d6e7f49a1',	'NETWORK_BONUS',	'network_bonus',	NULL,	500.00,	0.1000,	50.00,	0.10,	0.00,	0.45,	0.00,	0.45,	50.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 17:56:31.672463',	'2025-11-30 23:56:31.672463'),
('f99e887c-ac93-4935-b6aa-8a05af7a2715',	'56774264-3dbb-4c24-83cb-e9c4b35356c9',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	900.00,	0.1000,	90.00,	0.10,	0.00,	0.45,	40.50,	0.45,	40.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('fc401057-e056-4f1c-97ba-7700c7b90763',	'b711b7b8-8dc9-46ea-b70e-787dab4f3813',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1000.00,	0.1000,	100.00,	0.10,	0.00,	0.45,	45.00,	0.45,	45.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('cfbfa342-396d-40b2-abd4-9921e287cc9a',	'1ea69140-4932-406c-b5a6-86b37a6a31e5',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1100.00,	0.1000,	110.00,	0.10,	0.00,	0.45,	49.50,	0.45,	49.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-27 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('452981bd-e8e5-483a-94b3-4e5193352155',	'fdce7838-c916-4bf8-ae67-bea31ab9306c',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1200.00,	0.1000,	120.00,	0.10,	0.00,	0.45,	54.00,	0.45,	54.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-26 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('6b485ca2-7f6a-44fd-929e-5ee3147d5a26',	'47aa4075-d780-4092-9bae-0903074777a5',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1300.00,	0.1000,	130.00,	0.10,	0.00,	0.45,	58.50,	0.45,	58.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-25 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('5c93e739-3b07-4cbf-8977-05be68ee4f33',	'1ad833d5-5d45-4e70-9018-0b8ac15943e4',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1400.00,	0.1000,	140.00,	0.10,	0.00,	0.45,	63.00,	0.45,	63.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-24 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('77a92131-7369-4dbd-adf2-6ed28cc95832',	'b134399b-f98e-48da-ae37-ef78ca6ef2aa',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1500.00,	0.1000,	150.00,	0.10,	0.00,	0.45,	67.50,	0.45,	67.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-23 23:59:13.669791',	'2025-11-30 23:59:13.669791'),
('4edc6297-0e0a-4738-82f3-9e4b8aca77df',	'eb717701-bf90-4983-8dce-0796de17fa5f',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	800.00,	0.1000,	80.00,	0.10,	0.00,	0.45,	36.00,	0.45,	36.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 00:03:36.818427',	'2025-12-01 00:03:36.818427'),
('8257d94c-3e79-4d74-b79e-315afe96562a',	'1a2430a1-fcee-4c25-a3db-de79d54780f2',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	900.00,	0.1000,	90.00,	0.10,	0.00,	0.45,	40.50,	0.45,	40.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 00:03:36.818427',	'2025-12-01 00:03:36.818427'),
('db86a4c7-c130-49b8-89f0-53c4f22c3909',	'8411e766-ec96-4cc9-ab6d-4d3a706b4265',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1000.00,	0.1000,	100.00,	0.10,	0.00,	0.45,	45.00,	0.45,	45.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 00:03:36.818427',	'2025-12-01 00:03:36.818427'),
('28c993dc-7bb6-496c-9baf-ce908d7e3b34',	'76af7b61-4884-4322-8496-a273ae21e803',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	800.00,	0.1000,	80.00,	0.10,	0.00,	0.45,	36.00,	0.45,	36.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-30 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('ba63a9ea-5d19-492e-84ef-d243a6869c90',	'f06d4037-5a96-4486-93c1-ae2b2bc8fd7d',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	850.00,	0.1000,	85.00,	0.10,	0.00,	0.45,	38.25,	0.45,	38.25,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-29 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('a03faaf2-429e-43ed-aa20-4676dea046a7',	'dfd78098-8df3-44bf-82f7-a36c4688fe78',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	900.00,	0.1000,	90.00,	0.10,	0.00,	0.45,	40.50,	0.45,	40.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-28 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('6e169a90-3503-402b-9cf7-c0d1bb4d1bb8',	'7881fc2e-8cc4-40c2-995f-dd8bacc86189',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	950.00,	0.1000,	95.00,	0.10,	0.00,	0.45,	42.75,	0.45,	42.75,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-27 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('95b953e5-d250-47a8-a21a-ee7a73dc5358',	'8dcd76f7-693d-45fb-b269-df8a0c4fa8c4',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1000.00,	0.1000,	100.00,	0.10,	0.00,	0.45,	45.00,	0.45,	45.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-26 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('928d24c7-5a86-47ea-99b6-2ab6d9dccc1a',	'78408b7e-6f37-48b1-bccd-4f9e55f0b93a',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1050.00,	0.1000,	105.00,	0.10,	0.00,	0.45,	47.25,	0.45,	47.25,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-25 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('9e5a63a3-21b4-4e5f-b352-1ee132016a2c',	'bc9c8410-213d-4f6a-9f62-9de859c65e26',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1100.00,	0.1000,	110.00,	0.10,	0.00,	0.45,	49.50,	0.45,	49.50,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-24 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('c627a518-f88b-422b-8e94-c3ab383d6b5f',	'96dcd69e-47b0-4456-b576-d5972156f71b',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1150.00,	0.1000,	115.00,	0.10,	0.00,	0.45,	51.75,	0.45,	51.75,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-23 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('a92a1be7-6726-4567-b748-b9541d71f07d',	'01fae03e-fbf6-4bc4-9f2b-df20e599c20e',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1200.00,	0.1000,	120.00,	0.10,	0.00,	0.45,	54.00,	0.45,	54.00,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-22 00:06:42.283995',	'2025-12-01 00:06:42.283995'),
('64ac590b-bf18-408f-bbef-74851851ef3f',	'76647ce0-b7e6-4a69-b43c-86f301cec801',	'SECONDHAND_SALE',	'secondhand_sale',	NULL,	1250.00,	0.1000,	125.00,	0.10,	0.00,	0.45,	56.25,	0.45,	56.25,	7,	'COMPLETED',	NULL,	'AUTO',	'2025-11-21 00:06:42.283995',	'2025-12-01 00:06:42.283995');

DELIMITER ;;

CREATE TRIGGER "update_simulated_fp_transactions_updated_at" BEFORE UPDATE ON "public"."simulated_fp_transactions" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP VIEW IF EXISTS "user_finpoint_summary";
CREATE TABLE "user_finpoint_summary" ("recipient_user_id" uuid, "total_transactions" bigint, "total_orders_involved" bigint, "total_received" numeric, "total_spent" numeric, "current_finpoint" numeric, "from_own_purchase" numeric, "from_network" numeric, "from_system" numeric);


DROP TABLE IF EXISTS "user_insurance_selections";
CREATE TABLE "public"."user_insurance_selections" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "user_id" uuid NOT NULL,
    "insurance_product_id" uuid NOT NULL,
    "selected_at" timestamp DEFAULT now() NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "priority" integer DEFAULT '1',
    "notes" text,
    "created_at" timestamp DEFAULT now() NOT NULL,
    "updated_at" timestamp DEFAULT now() NOT NULL,
    "deactivated_at" timestamp,
    CONSTRAINT "user_insurance_selections_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

COMMENT ON TABLE "public"."user_insurance_selections" IS 'เก็บการเลือกผลิตภัณฑ์ประกันภัยของ user แต่ละคน (many-to-many relationship)';

COMMENT ON COLUMN "public"."user_insurance_selections"."user_id" IS 'UUID ของ user ที่เลือก';

COMMENT ON COLUMN "public"."user_insurance_selections"."insurance_product_id" IS 'UUID ของผลิตภัณฑ์ประกันที่ถูกเลือก';

COMMENT ON COLUMN "public"."user_insurance_selections"."selected_at" IS 'เวลาที่เลือกผลิตภัณฑ์นี้';

COMMENT ON COLUMN "public"."user_insurance_selections"."is_active" IS 'สถานะการเลือก (true = กำลังใช้งาน, false = ยกเลิกแล้ว)';

COMMENT ON COLUMN "public"."user_insurance_selections"."priority" IS 'ลำดับความสำคัญ (1 = สูงสุด) ถ้าเลือกหลายตัวใน level เดียวกัน';

COMMENT ON COLUMN "public"."user_insurance_selections"."notes" IS 'หมายเหตุหรือข้อมูลเพิ่มเติม';

COMMENT ON COLUMN "public"."user_insurance_selections"."deactivated_at" IS 'เวลาที่ยกเลิกการเลือก (auto-set เมื่อ is_active = false)';

CREATE INDEX idx_user_insurance_selections_user_id ON public.user_insurance_selections USING btree (user_id);

CREATE INDEX idx_user_insurance_selections_insurance_product_id ON public.user_insurance_selections USING btree (insurance_product_id);

CREATE INDEX idx_user_insurance_selections_is_active ON public.user_insurance_selections USING btree (is_active);

CREATE INDEX idx_user_insurance_selections_user_active ON public.user_insurance_selections USING btree (user_id, is_active) WHERE (is_active = true);

CREATE INDEX idx_user_insurance_selections_priority ON public.user_insurance_selections USING btree (user_id, priority, is_active);

INSERT INTO "user_insurance_selections" ("id", "user_id", "insurance_product_id", "selected_at", "is_active", "priority", "notes", "created_at", "updated_at", "deactivated_at") VALUES
('e7966ba0-e507-438a-8212-a77763bf7a02',	'00000000-0000-0000-0000-000000000000',	'c2909c9b-7ab1-4115-9d68-3c0006322e01',	'2025-12-02 00:57:37.66092',	'1',	1,	NULL,	'2025-12-02 00:57:37.66092',	'2025-12-02 00:57:37.66092',	NULL),
('7eca0ea6-17be-4290-9cb0-c10afb349bb4',	'00000000-0000-0000-0000-000000000000',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	'2025-12-02 00:57:37.665607',	'1',	2,	NULL,	'2025-12-02 00:57:37.665607',	'2025-12-02 00:57:37.665607',	NULL),
('1a8e4a5e-e413-4de2-a5f2-c219068dbdf4',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'e13542cb-f6d0-4853-b95f-342f5841d9b8',	'2025-12-02 00:57:37.666918',	'1',	1,	NULL,	'2025-12-02 00:57:37.666918',	'2025-12-02 00:57:37.666918',	NULL),
('364911ee-42cf-4377-bf36-05ffb812c5c1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'c2909c9b-7ab1-4115-9d68-3c0006322e01',	'2025-12-02 01:03:27.454763',	'1',	1,	NULL,	'2025-12-02 01:03:27.454763',	'2025-12-02 01:03:27.454763',	NULL),
('b0e09bdf-4a55-4322-a2f9-65de067e3697',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'ad0977d1-7fa7-47f7-b468-eb08c2eedd6d',	'2025-12-02 00:57:37.668054',	'0',	2,	NULL,	'2025-12-02 00:57:37.668054',	'2025-12-02 01:03:47.98619',	'2025-12-02 01:03:47.98619'),
('52edd77b-9a1f-44a4-bc09-7b880cac9120',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'bee731bb-3958-49f8-b030-21d64ecf07ef',	'2025-12-02 01:09:14.309219',	'1',	1,	NULL,	'2025-12-02 01:09:14.309219',	'2025-12-02 01:09:14.309219',	NULL),
('37420ec8-b632-440a-8ccd-57b75e71fda1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'a9f48a68-1fe2-4277-ad6f-5e213b4c8d26',	'2025-12-02 01:09:21.438537',	'1',	1,	NULL,	'2025-12-02 01:09:21.438537',	'2025-12-02 01:09:21.438537',	NULL),
('acdaa8a5-a32b-46ea-80c8-ea954e0c9ca0',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	'2025-12-02 01:03:27.464862',	'0',	1,	NULL,	'2025-12-02 01:03:27.464862',	'2025-12-03 01:44:16.812576',	'2025-12-03 01:44:16.812576'),
('adb67765-695b-4f4b-bf1a-e61b1f18fea8',	'ba601584-060a-4f03-8702-7abbf09353c0',	'c2909c9b-7ab1-4115-9d68-3c0006322e01',	'2025-12-03 13:14:40.843038',	'1',	1,	NULL,	'2025-12-03 13:14:40.843038',	'2025-12-03 13:14:40.843038',	NULL),
('6d066869-064d-4867-9ed2-279443aca319',	'ba601584-060a-4f03-8702-7abbf09353c0',	'ba36a892-fc97-4583-bed4-9acaffb7b083',	'2025-12-03 13:14:40.870827',	'1',	1,	NULL,	'2025-12-03 13:14:40.870827',	'2025-12-03 13:14:40.870827',	NULL),
('35ae55d9-d3fb-44aa-83bc-75b469acaedc',	'ba601584-060a-4f03-8702-7abbf09353c0',	'e13542cb-f6d0-4853-b95f-342f5841d9b8',	'2025-12-04 00:10:42.906154',	'1',	1,	NULL,	'2025-12-04 00:10:42.906154',	'2025-12-04 00:10:42.906154',	NULL),
('6ded5359-c65e-40b1-bc66-15bd9aaaffb3',	'ba601584-060a-4f03-8702-7abbf09353c0',	'8e2d0165-7549-44e0-8b43-5f8917172905',	'2025-12-04 00:28:04.896282',	'1',	1,	NULL,	'2025-12-04 00:28:04.896282',	'2025-12-04 00:28:04.896282',	NULL);

DELIMITER ;;

CREATE TRIGGER "trigger_user_insurance_selections_deactivated_at" BEFORE UPDATE ON "public"."user_insurance_selections" FOR EACH ROW EXECUTE FUNCTION update_user_insurance_selections_deactivated_at();;

CREATE TRIGGER "trigger_user_insurance_selections_updated_at" BEFORE UPDATE ON "public"."user_insurance_selections" FOR EACH ROW EXECUTE FUNCTION update_user_insurance_selections_updated_at();;

DELIMITER ;

DROP TABLE IF EXISTS "users";
CREATE TABLE "public"."users" (
    "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
    "world_id" character varying(10),
    "username" character varying(255) NOT NULL,
    "email" character varying(255),
    "phone" character varying(50),
    "first_name" character varying(255),
    "last_name" character varying(255),
    "avatar_url" text,
    "profile_image_filename" character varying(255),
    "bio" text,
    "location" jsonb,
    "preferred_currency" character varying(3) DEFAULT 'THB',
    "language" character varying(10) DEFAULT 'th',
    "is_verified" boolean DEFAULT false,
    "verification_level" integer DEFAULT '0',
    "trust_score" numeric(10,2) DEFAULT '0.0',
    "total_sales" integer DEFAULT '0',
    "total_purchases" integer DEFAULT '0',
    "estimated_inventory_value" numeric(15,2) DEFAULT '0.0',
    "estimated_item_count" integer DEFAULT '0',
    "run_number" integer NOT NULL,
    "parent_id" uuid,
    "child_count" integer DEFAULT '0' NOT NULL,
    "max_children" integer DEFAULT '5' NOT NULL,
    "acf_accepting" boolean DEFAULT true NOT NULL,
    "inviter_id" uuid,
    "invite_code" character varying(50),
    "level" integer DEFAULT '0' NOT NULL,
    "user_type" character varying(50) DEFAULT 'Atta' NOT NULL,
    "regist_type" character varying(50) DEFAULT 'normal' NOT NULL,
    "own_finpoint" numeric(15,2) DEFAULT '0' NOT NULL,
    "total_finpoint" numeric(15,2) DEFAULT '0' NOT NULL,
    "max_network" integer DEFAULT '19531' NOT NULL,
    "is_active" boolean DEFAULT true,
    "is_suspended" boolean DEFAULT false,
    "last_login" timestamp,
    "password_hash" character varying(255),
    "address_number" character varying(50),
    "address_street" character varying(255),
    "address_district" character varying(100),
    "address_province" character varying(100),
    "address_postal_code" character varying(20),
    "created_at" bigint DEFAULT '((EXTRACT(epoch FROM now()) * (1000)::numeric))',
    "updated_at" bigint DEFAULT '((EXTRACT(epoch FROM now()) * (1000)::numeric))',
    "upline_id" jsonb DEFAULT '[]',
    CONSTRAINT "users_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "users_verification_level_check" CHECK (((verification_level >= 0) AND (verification_level <= 4))),
    CONSTRAINT "users_max_children_check" CHECK (((max_children >= 1) AND (max_children <= 5))),
    CONSTRAINT "users_level_check" CHECK ((level >= 0)),
    CONSTRAINT "users_estimated_inventory_value_check" CHECK ((estimated_inventory_value >= (0)::numeric)),
    CONSTRAINT "users_estimated_item_count_check" CHECK ((estimated_item_count >= 0))
)
WITH (oids = false);

COMMENT ON COLUMN "public"."users"."upline_id" IS 'Array of upline user IDs (up to 6 levels), ordered from closest to farthest parent';

CREATE UNIQUE INDEX users_world_id_key ON public.users USING btree (world_id);

CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username);

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

CREATE UNIQUE INDEX users_run_number_key ON public.users USING btree (run_number);

CREATE UNIQUE INDEX users_invite_code_key ON public.users USING btree (invite_code);

CREATE INDEX idx_users_world_id ON public.users USING btree (world_id);

CREATE INDEX idx_users_username ON public.users USING btree (username);

CREATE INDEX idx_users_email ON public.users USING btree (email);

CREATE INDEX idx_users_run_number ON public.users USING btree (run_number);

CREATE INDEX idx_users_parent_id ON public.users USING btree (parent_id);

CREATE INDEX idx_users_inviter_id ON public.users USING btree (inviter_id);

CREATE INDEX idx_users_level ON public.users USING btree (level);

CREATE INDEX idx_users_acf_accepting ON public.users USING btree (acf_accepting) WHERE (acf_accepting = true);

CREATE INDEX idx_users_estimated_value ON public.users USING btree (estimated_inventory_value) WHERE (estimated_inventory_value > (0)::numeric);

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);

CREATE INDEX idx_users_upline_id_gin ON public.users USING gin (upline_id);

CREATE INDEX idx_users_upline_count ON public.users USING btree (jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)));

INSERT INTO "users" ("id", "world_id", "username", "email", "phone", "first_name", "last_name", "avatar_url", "profile_image_filename", "bio", "location", "preferred_currency", "language", "is_verified", "verification_level", "trust_score", "total_sales", "total_purchases", "estimated_inventory_value", "estimated_item_count", "run_number", "parent_id", "child_count", "max_children", "acf_accepting", "inviter_id", "invite_code", "level", "user_type", "regist_type", "own_finpoint", "total_finpoint", "max_network", "is_active", "is_suspended", "last_login", "password_hash", "address_number", "address_street", "address_district", "address_province", "address_postal_code", "created_at", "updated_at", "upline_id") VALUES
('4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'25AAA0001',	'somchai_jaidee',	'somchai@fingrow.com',	'0812345678',	'สมชาย',	'ใจดี',	'/uploads/profiles/4d003630-3ed6-4d80-89fd-5c1d2f017be1_1764809145586.jpg',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1_1764809145586.jpg',	NULL,	NULL,	'THB',	'th',	'1',	3,	95.50,	0,	0,	0.00,	0,	1,	'00000000-0000-0000-0000-000000000000',	5,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'SOMCHAI2025',	1,	'Atta',	'normal',	3250.00,	12500.00,	19531,	'1',	'0',	NULL,	NULL,	'123/45',	'ถนนสุขุมวิท',	'คลองเตย',	'กรุงเทพมหานคร',	'10110',	1764480950759,	1764809146000,	'["00000000-0000-0000-0000-000000000000"]'),
('00000000-0000-0000-0000-000000000000',	'25AAA0000',	'system_root',	NULL,	NULL,	NULL,	NULL,	'/uploads/profiles/00000000-0000-0000-0000-000000000000_1764981172830.png',	'00000000-0000-0000-0000-000000000000_1764981172830.png',	NULL,	NULL,	'THB',	'th',	'0',	0,	0.00,	0,	0,	0.00,	0,	0,	NULL,	5,	1,	'1',	NULL,	'SYSTEM0NJ8',	0,	'System',	'system',	0.00,	0.00,	19531,	'1',	'0',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	1763900002167,	1764981173000,	'[]'),
('9350d0b2-5d70-4105-82ac-13021a62b868',	'25AAA0003',	'supattra_sawadee',	'supattra@fingrow.com',	'0834567890',	'สุพัตรา',	'สวัสดี',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจลงทุนในระบบ Fingrow',	NULL,	'THB',	'th',	'1',	1,	75.00,	10,	8,	0.00,	0,	3,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	5,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'SUPATTRA2025',	2,	'Atta',	'normal',	800.00,	2500.00,	19531,	'1',	'0',	NULL,	NULL,	'789/12',	'ถนนรัชดาภิเษก',	'ห้วยขวาง',	'กรุงเทพมหานคร',	'10310',	1764498121585,	1764547602284,	'["4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('b86923e4-ae78-4dad-a5d1-070f72006c83',	'25AAA0005',	'apinya_sri',	'apinya@fingrow.com',	'0856789012',	'อภิญญา',	'ศรีสุข',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจการลงทุนและประกัน',	NULL,	'THB',	'th',	'1',	2,	78.50,	15,	10,	0.00,	0,	5,	'00000000-0000-0000-0000-000000000000',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'APINYA2025',	1,	'Atta',	'normal',	1800.00,	5200.00,	19531,	'1',	'0',	NULL,	NULL,	'555/21',	'ถนนวิภาวดีรังสิต',	'จตุจักร',	'กรุงเทพมหานคร',	'10900',	1764524048965,	1764524048965,	'["00000000-0000-0000-0000-000000000000"]'),
('aeaba876-100a-4da3-ae90-ae175bfdd5aa',	'25AAA0006',	'preecha_mana',	'preecha@fingrow.com',	'0867890123',	'ปรีชา',	'มานะ',	NULL,	NULL,	'ผู้ประกอบการที่ต้องการขยายเครือข่าย',	NULL,	'THB',	'th',	'1',	3,	88.00,	22,	16,	0.00,	0,	6,	'00000000-0000-0000-0000-000000000000',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'PREECHA2025',	1,	'Atta',	'normal',	2500.00,	7800.00,	19531,	'1',	'0',	NULL,	NULL,	'888/77',	'ถนนลาดพร้าว',	'จตุจักร',	'กรุงเทพมหานคร',	'10900',	1764524049965,	1764524049965,	'["00000000-0000-0000-0000-000000000000"]'),
('d77ef8b3-df9f-48b7-8eed-485a0a592abd',	'25AAA0009',	'wichai_dee',	'wichai@fingrow.com',	'0890123456',	'วิชัย',	'ดี',	NULL,	NULL,	'นักลงทุนที่สนใจการประกัน',	NULL,	'THB',	'th',	'1',	2,	84.00,	19,	14,	0.00,	0,	9,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'WICHAI2025',	2,	'Atta',	'normal',	2200.00,	6800.00,	19531,	'1',	'0',	NULL,	NULL,	'567/89',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764546997672,	1764546997672,	'["4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('ba601584-060a-4f03-8702-7abbf09353c0',	'25AAA0002',	'somsri_rakdee',	'somsri@fingrow.com',	'0823456789',	'สมศรี',	'รักดี',	'/uploads/profiles/ba601584-060a-4f03-8702-7abbf09353c0_1764810210239.jpg',	'ba601584-060a-4f03-8702-7abbf09353c0_1764810210239.jpg',	'สมาชิกใหม่ของ Fingrow ที่สนใจซื้อขายของมือสอง',	NULL,	'THB',	'th',	'1',	2,	87.50,	25,	15,	0.00,	0,	2,	'00000000-0000-0000-0000-000000000000',	5,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'SOMSRI2025',	1,	'Atta',	'normal',	1500.00,	5000.00,	19531,	'1',	'0',	NULL,	NULL,	'456/78',	'ถนนพระราม 4',	'คลองเตย',	'กรุงเทพมหานคร',	'10110',	1764480950761,	1764810210000,	'["00000000-0000-0000-0000-000000000000"]'),
('7afd6d4f-604e-4273-bd80-e1419dd43c03',	'25AAA0004',	'nattawut_chai',	'nattawut@fingrow.com',	'0845678901',	'ณัฐวุฒิ',	'ชัยชนะ',	NULL,	NULL,	'นักลงทุนในระบบ Fingrow ที่สนใจธุรกิจประกัน',	NULL,	'THB',	'th',	'1',	2,	82.00,	18,	12,	0.00,	0,	4,	'00000000-0000-0000-0000-000000000000',	12,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'NATTAWUT2025',	1,	'Atta',	'normal',	2100.00,	6500.00,	19531,	'1',	'0',	NULL,	NULL,	'321/99',	'ถนนเพชรบุรี',	'ราชเทวี',	'กรุงเทพมหานคร',	'10400',	1764524047965,	1764935751000,	'["00000000-0000-0000-0000-000000000000"]'),
('1ea69140-4932-406c-b5a6-86b37a6a31e5',	'25AAA0014',	'chaiwat_yim',	'chaiwat@fingrow.com',	'0845678901',	'ชัยวัฒน์',	'ยิ้ม',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	82.50,	13,	11,	0.00,	0,	14,	'ba601584-060a-4f03-8702-7abbf09353c0',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'CHAIWAT2025',	2,	'Atta',	'normal',	1900.00,	5700.00,	19531,	'1',	'0',	NULL,	NULL,	'130/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547156670,	1764547156670,	'["ba601584-060a-4f03-8702-7abbf09353c0", "00000000-0000-0000-0000-000000000000"]'),
('87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	'25AAA0007',	'kanya_dee',	'kanya@fingrow.com',	'0878901234',	'กัญญา',	'ดี',	NULL,	NULL,	'ผู้สนใจการลงทุนในระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	80.00,	14,	11,	0.00,	0,	7,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	5,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'KANYA2025',	2,	'Atta',	'normal',	1950.00,	5800.00,	19531,	'1',	'0',	NULL,	NULL,	'777/55',	'ถนนงามวงศ์วาน',	'บางเขน',	'กรุงเทพมหานคร',	'10220',	1764546990896,	1764547602284,	'["4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('7b8b9dc4-4e6a-4c99-8988-6c176e2904c2',	'25AAA0010',	'pensri_chai',	'pensri@fingrow.com',	'0801234567',	'เพ็ญศรี',	'ชัย',	NULL,	NULL,	'ผู้สนใจธุรกิจขายของมือสอง',	NULL,	'THB',	'th',	'1',	1,	72.50,	13,	10,	0.00,	0,	10,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'PENSRI2025',	2,	'Atta',	'normal',	1750.00,	5100.00,	19531,	'1',	'0',	NULL,	NULL,	'890/12',	'ถนนพหลโยธิน',	'จตุจักร',	'กรุงเทพมหานคร',	'10900',	1764546998672,	1764546998672,	'["4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('56774264-3dbb-4c24-83cb-e9c4b35356c9',	'25AAA0012',	'rattana_porn',	'rattana@fingrow.com',	'0823456789',	'รัตนา',	'พร',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	77.50,	11,	9,	0.00,	0,	12,	'ba601584-060a-4f03-8702-7abbf09353c0',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'RATTANA2025',	2,	'Atta',	'normal',	1700.00,	5200.00,	19531,	'1',	'0',	NULL,	NULL,	'110/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547154670,	1764547154670,	'["ba601584-060a-4f03-8702-7abbf09353c0", "00000000-0000-0000-0000-000000000000"]'),
('b711b7b8-8dc9-46ea-b70e-787dab4f3813',	'25AAA0013',	'sunan_jai',	'sunan@fingrow.com',	'0834567890',	'สุนันท์',	'ใจ',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	80.00,	12,	10,	0.00,	0,	13,	'ba601584-060a-4f03-8702-7abbf09353c0',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'SUNAN2025',	2,	'Atta',	'normal',	2300.00,	7100.00,	19531,	'1',	'0',	NULL,	NULL,	'120/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547155670,	1764547155670,	'["ba601584-060a-4f03-8702-7abbf09353c0", "00000000-0000-0000-0000-000000000000"]'),
('fdce7838-c916-4bf8-ae67-bea31ab9306c',	'25AAA0015',	'lalita_kaew',	'lalita@fingrow.com',	'0856789012',	'ลลิตา',	'แก้ว',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	85.00,	14,	12,	0.00,	0,	15,	'ba601584-060a-4f03-8702-7abbf09353c0',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'LALITA2025',	2,	'Atta',	'normal',	2100.00,	6400.00,	19531,	'1',	'0',	NULL,	NULL,	'140/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547157670,	1764547157670,	'["ba601584-060a-4f03-8702-7abbf09353c0", "00000000-0000-0000-0000-000000000000"]'),
('47aa4075-d780-4092-9bae-0903074777a5',	'25AAA0016',	'thaworn_suk',	'thaworn@fingrow.com',	'0867890123',	'ถาวร',	'สุข',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	87.50,	15,	13,	0.00,	0,	16,	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'THAWORN2025',	2,	'Atta',	'normal',	2600.00,	8200.00,	19531,	'1',	'0',	NULL,	NULL,	'150/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547158670,	1764547158670,	'["7afd6d4f-604e-4273-bd80-e1419dd43c03", "00000000-0000-0000-0000-000000000000"]'),
('78e83bc3-7fc2-4528-9909-8154b641fc08',	'25AAA0008',	'manee_suk',	'manee@fingrow.com',	'0889012345',	'มณี',	'สุข',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	76.00,	12,	9,	0.00,	0,	8,	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	10,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'MANEE2025',	2,	'Atta',	'normal',	1600.00,	4800.00,	19531,	'1',	'0',	NULL,	NULL,	'234/56',	'ถนนพระราม 4',	'คลองเตย',	'กรุงเทพมหานคร',	'10110',	1764546996672,	1764938362000,	'["4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('ee579d17-2a8f-46df-9f09-8a7d6e7f49a1',	'25AAA0011',	'somkid_sri',	'somkid@fingrow.com',	'0812345678',	'สมคิด',	'ศรี',	NULL,	NULL,	'ผู้ประกอบการที่ต้องการขยายเครือข่าย',	NULL,	'THB',	'th',	'1',	3,	86.50,	21,	15,	0.00,	0,	11,	'ba601584-060a-4f03-8702-7abbf09353c0',	16,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'SOMKID2025',	2,	'Atta',	'normal',	2400.00,	7500.00,	19531,	'1',	'0',	NULL,	NULL,	'345/67',	'ถนนรัชดาภิเษก',	'ห้วยขวาง',	'กรุงเทพมหานคร',	'10310',	1764546999672,	1764939215000,	'["ba601584-060a-4f03-8702-7abbf09353c0", "00000000-0000-0000-0000-000000000000"]'),
('1ad833d5-5d45-4e70-9018-0b8ac15943e4',	'25AAA0017',	'narong_dee',	'narong@fingrow.com',	'0878901234',	'ณรงค์',	'ดี',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	90.00,	16,	14,	0.00,	0,	17,	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'NARONG2025',	2,	'Atta',	'normal',	1800.00,	5400.00,	19531,	'1',	'0',	NULL,	NULL,	'160/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547159670,	1764547159670,	'["7afd6d4f-604e-4273-bd80-e1419dd43c03", "00000000-0000-0000-0000-000000000000"]'),
('b134399b-f98e-48da-ae37-ef78ca6ef2aa',	'25AAA0018',	'pranom_chai',	'pranom@fingrow.com',	'0889012345',	'ประนอม',	'ชัย',	NULL,	NULL,	'สมาชิกใหม่ที่สนใจระบบ Fingrow',	NULL,	'THB',	'th',	'1',	2,	92.50,	17,	15,	0.00,	0,	18,	'7afd6d4f-604e-4273-bd80-e1419dd43c03',	0,	5,	'1',	'00000000-0000-0000-0000-000000000000',	'PRANOM2025',	2,	'Atta',	'normal',	2200.00,	6900.00,	19531,	'1',	'0',	NULL,	NULL,	'170/12',	'ถนนสุขุมวิท',	'วัฒนา',	'กรุงเทพมหานคร',	'10110',	1764547160670,	1764547160670,	'["7afd6d4f-604e-4273-bd80-e1419dd43c03", "00000000-0000-0000-0000-000000000000"]'),
('eb717701-bf90-4983-8dce-0796de17fa5f',	'25AAA0019',	'wipawee_chan',	'wipawee@fingrow.com',	'0890123456',	'วิภาวี',	'จันทร์',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Supattra',	NULL,	'THB',	'th',	'1',	1,	73.00,	9,	7,	0.00,	0,	19,	'9350d0b2-5d70-4105-82ac-13021a62b868',	0,	5,	'1',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'WIPAWEE2025',	3,	'Atta',	'normal',	1500.00,	4500.00,	19531,	'1',	'0',	NULL,	NULL,	'210/45',	'ถนนรัชดาภิเษก',	'ห้วยขวาง',	'กรุงเทพมหานคร',	'10310',	1764547517818,	1764547517818,	'["9350d0b2-5d70-4105-82ac-13021a62b868", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('1a2430a1-fcee-4c25-a3db-de79d54780f2',	'25AAA0020',	'sarawut_song',	'sarawut@fingrow.com',	'0801234567',	'สราวุฒิ',	'ทรง',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Supattra',	NULL,	'THB',	'th',	'1',	1,	76.00,	10,	8,	0.00,	0,	20,	'9350d0b2-5d70-4105-82ac-13021a62b868',	0,	5,	'1',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'SARAWUT2025',	3,	'Atta',	'normal',	2000.00,	6200.00,	19531,	'1',	'0',	NULL,	NULL,	'220/45',	'ถนนรัชดาภิเษก',	'ห้วยขวาง',	'กรุงเทพมหานคร',	'10310',	1764547518818,	1764547518818,	'["9350d0b2-5d70-4105-82ac-13021a62b868", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('8411e766-ec96-4cc9-ab6d-4d3a706b4265',	'25AAA0021',	'nida_porn',	'nida@fingrow.com',	'0812345678',	'นิดา',	'พร',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Supattra',	NULL,	'THB',	'th',	'1',	1,	79.00,	11,	9,	0.00,	0,	21,	'9350d0b2-5d70-4105-82ac-13021a62b868',	0,	5,	'1',	'9350d0b2-5d70-4105-82ac-13021a62b868',	'NIDA2025',	3,	'Atta',	'normal',	1800.00,	5400.00,	19531,	'1',	'0',	NULL,	NULL,	'230/45',	'ถนนรัชดาภิเษก',	'ห้วยขวาง',	'กรุงเทพมหานคร',	'10310',	1764547519818,	1764547519818,	'["9350d0b2-5d70-4105-82ac-13021a62b868", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('76af7b61-4884-4322-8496-a273ae21e803',	'25AAA0022',	'anong_kaew',	'anong@fingrow.com',	'0823456780',	'อนงค์',	'แก้ว',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	73.50,	10,	8,	0.00,	0,	22,	'9350d0b2-5d70-4105-82ac-13021a62b868',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'ANONG2025',	3,	'Atta',	'normal',	1600.00,	4900.00,	19531,	'1',	'0',	NULL,	NULL,	'310/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547803284,	1764547803284,	'["9350d0b2-5d70-4105-82ac-13021a62b868", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('f06d4037-5a96-4486-93c1-ae2b2bc8fd7d',	'25AAA0023',	'boonmee_rak',	'boonmee@fingrow.com',	'0834567891',	'บุญมี',	'รักษ์',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	75.00,	11,	9,	0.00,	0,	23,	'9350d0b2-5d70-4105-82ac-13021a62b868',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'BOONMEE2025',	3,	'Atta',	'normal',	1900.00,	5800.00,	19531,	'1',	'0',	NULL,	NULL,	'320/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547804284,	1764547804284,	'["9350d0b2-5d70-4105-82ac-13021a62b868", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('dfd78098-8df3-44bf-82f7-a36c4688fe78',	'25AAA0024',	'chompoo_suk',	'chompoo@fingrow.com',	'0845678902',	'ชมพู',	'สุข',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	76.50,	12,	10,	0.00,	0,	24,	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'CHOMPOO2025',	3,	'Atta',	'normal',	2100.00,	6500.00,	19531,	'1',	'0',	NULL,	NULL,	'330/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547805284,	1764547805284,	'["87dd0b52-c24c-4fcf-acd0-3e58c483eb25", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('7881fc2e-8cc4-40c2-995f-dd8bacc86189',	'25AAA0025',	'darika_porn',	'darika@fingrow.com',	'0856789013',	'ดาริกา',	'พร',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	78.00,	13,	11,	0.00,	0,	25,	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'DARIKA2025',	3,	'Atta',	'normal',	1750.00,	5300.00,	19531,	'1',	'0',	NULL,	NULL,	'340/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547806284,	1764547806284,	'["87dd0b52-c24c-4fcf-acd0-3e58c483eb25", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('8dcd76f7-693d-45fb-b269-df8a0c4fa8c4',	'25AAA0026',	'ekachai_dee',	'ekachai@fingrow.com',	'0867890124',	'เอกชัย',	'ดี',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	79.50,	14,	12,	0.00,	0,	26,	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'EKACHAI2025',	3,	'Atta',	'normal',	2200.00,	6800.00,	19531,	'1',	'0',	NULL,	NULL,	'350/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547807284,	1764547807284,	'["87dd0b52-c24c-4fcf-acd0-3e58c483eb25", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('78408b7e-6f37-48b1-bccd-4f9e55f0b93a',	'25AAA0027',	'fueng_chai',	'fueng@fingrow.com',	'0878901235',	'เฟื่อง',	'ชัย',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	81.00,	15,	13,	0.00,	0,	27,	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'FUENG2025',	3,	'Atta',	'normal',	1850.00,	5600.00,	19531,	'1',	'0',	NULL,	NULL,	'360/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547808284,	1764547808284,	'["87dd0b52-c24c-4fcf-acd0-3e58c483eb25", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('bc9c8410-213d-4f6a-9f62-9de859c65e26',	'25AAA0028',	'ganya_yim',	'ganya@fingrow.com',	'0889012346',	'กัญญา',	'ยิ้ม',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	82.50,	16,	14,	0.00,	0,	28,	'87dd0b52-c24c-4fcf-acd0-3e58c483eb25',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'GANYA2025',	3,	'Atta',	'normal',	2000.00,	6100.00,	19531,	'1',	'0',	NULL,	NULL,	'370/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547809284,	1764547809284,	'["87dd0b52-c24c-4fcf-acd0-3e58c483eb25", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('96dcd69e-47b0-4456-b576-d5972156f71b',	'25AAA0029',	'hiran_song',	'hiran@fingrow.com',	'0890123457',	'หิรัญ',	'ทรง',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	84.00,	17,	15,	0.00,	0,	29,	'78e83bc3-7fc2-4528-9909-8154b641fc08',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'HIRAN2025',	3,	'Atta',	'normal',	1950.00,	5950.00,	19531,	'1',	'0',	NULL,	NULL,	'380/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547810284,	1764547810284,	'["78e83bc3-7fc2-4528-9909-8154b641fc08", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('01fae03e-fbf6-4bc4-9f2b-df20e599c20e',	'25AAA0030',	'itsara_won',	'itsara@fingrow.com',	'0801234568',	'อิสระ',	'วรรณ',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	85.50,	18,	16,	0.00,	0,	30,	'78e83bc3-7fc2-4528-9909-8154b641fc08',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'ITSARA2025',	3,	'Atta',	'normal',	2150.00,	6600.00,	19531,	'1',	'0',	NULL,	NULL,	'390/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547811284,	1764547811284,	'["78e83bc3-7fc2-4528-9909-8154b641fc08", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('76647ce0-b7e6-4a69-b43c-86f301cec801',	'25AAA0031',	'jira_pong',	'jira@fingrow.com',	'0812345679',	'จิรา',	'พงษ์',	NULL,	NULL,	'สมาชิกใหม่ที่ถูกชวนโดย Somchai',	NULL,	'THB',	'th',	'1',	2,	87.00,	19,	17,	0.00,	0,	31,	'78e83bc3-7fc2-4528-9909-8154b641fc08',	0,	5,	'1',	'4d003630-3ed6-4d80-89fd-5c1d2f017be1',	'JIRA2025',	3,	'Atta',	'normal',	1800.00,	5500.00,	19531,	'1',	'0',	NULL,	NULL,	'400/23',	'ถนนพระราม 3',	'บางโพ',	'กรุงเทพมหานคร',	'10160',	1764547812284,	1764547812284,	'["78e83bc3-7fc2-4528-9909-8154b641fc08", "4d003630-3ed6-4d80-89fd-5c1d2f017be1", "00000000-0000-0000-0000-000000000000"]'),
('6f35b41e-76e2-44e6-9ab3-ea9987d47699',	'25V26X',	'johunna',	'johunna@gmail.com',	NULL,	'nuttapong',	'chaisuko',	'https://lh3.googleusercontent.com/a/ACg8ocKLqyvBR_rXzlfzeFISOrKtAk07hpeL8IKieJRKOLeQ_EQuqLBU=s96-c',	NULL,	NULL,	NULL,	'THB',	'th',	'1',	1,	50.00,	0,	0,	0.00,	0,	32,	'ee579d17-2a8f-46df-9f09-8a7d6e7f49a1',	0,	5,	'1',	'ba601584-060a-4f03-8702-7abbf09353c0',	'JOHUNN04G9',	1,	'member',	'google',	0.00,	0.00,	7,	'1',	'0',	'2025-12-05 19:53:34.861',	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	1764939214861,	1764939214861,	'[]');

DELIMITER ;;

CREATE TRIGGER "trigger_auto_update_upline_id" BEFORE INSERT OR UPDATE OF ON "public"."users" FOR EACH ROW EXECUTE FUNCTION auto_update_upline_id();;

CREATE TRIGGER "update_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();;

DELIMITER ;

DROP VIEW IF EXISTS "v_active_users_acf";
CREATE TABLE "v_active_users_acf" ("id" uuid, "world_id" character varying(10), "username" character varying(255), "run_number" integer, "parent_id" uuid, "level" integer, "child_count" integer, "max_children" integer, "acf_accepting" boolean, "own_finpoint" numeric(15,2), "total_finpoint" numeric(15,2), "created_at" bigint);


DROP VIEW IF EXISTS "v_simulated_fp_summary";
CREATE TABLE "v_simulated_fp_summary" ("user_id" uuid, "world_id" character varying(10), "username" character varying(255), "total_transactions" bigint, "total_fp_earned" numeric, "total_fp_spent" numeric, "net_fp_balance" numeric);


DROP VIEW IF EXISTS "v_user_network_summary";
CREATE TABLE "v_user_network_summary" ("id" uuid, "world_id" character varying(10), "username" character varying(255), "run_number" integer, "level" integer, "child_count" integer, "max_children" integer, "acf_accepting" boolean, "total_referrals" bigint, "total_earnings" numeric);


ALTER TABLE ONLY "public"."addresses" ADD CONSTRAINT "addresses_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."categories" ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY "public"."chat_rooms" ADD CONSTRAINT "chat_rooms_buyer_id_fkey" FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."chat_rooms" ADD CONSTRAINT "chat_rooms_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."chat_rooms" ADD CONSTRAINT "chat_rooms_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."commission_pool_distribution" ADD CONSTRAINT "commission_pool_distribution_insurance_order_id_fkey" FOREIGN KEY (insurance_order_id) REFERENCES insurance_orders(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."commission_pool_distribution" ADD CONSTRAINT "commission_pool_distribution_recipient_user_id_fkey" FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE RESTRICT NOT DEFERRABLE;

ALTER TABLE ONLY "public"."earnings" ADD CONSTRAINT "earnings_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."earnings" ADD CONSTRAINT "earnings_source_user_id_fkey" FOREIGN KEY (source_user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."earnings" ADD CONSTRAINT "earnings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."favorites" ADD CONSTRAINT "favorites_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."favorites" ADD CONSTRAINT "favorites_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."insurance_orders" ADD CONSTRAINT "insurance_orders_insurance_product_id_fkey" FOREIGN KEY (insurance_product_id) REFERENCES insurance_product(id) ON DELETE RESTRICT NOT DEFERRABLE;
ALTER TABLE ONLY "public"."insurance_orders" ADD CONSTRAINT "insurance_orders_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT NOT DEFERRABLE;

ALTER TABLE ONLY "public"."insurance_product" ADD CONSTRAINT "fk_created_by" FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."insurance_product" ADD CONSTRAINT "fk_seller" FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."insurance_product" ADD CONSTRAINT "fk_updated_by" FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY "public"."messages" ADD CONSTRAINT "messages_chat_room_id_fkey" FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."order_items" ADD CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT NOT DEFERRABLE;

ALTER TABLE ONLY "public"."orders" ADD CONSTRAINT "orders_buyer_id_fkey" FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE RESTRICT NOT DEFERRABLE;
ALTER TABLE ONLY "public"."orders" ADD CONSTRAINT "orders_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE RESTRICT NOT DEFERRABLE;

ALTER TABLE ONLY "public"."payment_methods" ADD CONSTRAINT "payment_methods_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."product_images" ADD CONSTRAINT "product_images_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."products" ADD CONSTRAINT "products_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."referrals" ADD CONSTRAINT "referrals_referee_id_fkey" FOREIGN KEY (referee_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."referrals" ADD CONSTRAINT "referrals_referrer_id_fkey" FOREIGN KEY (referrer_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."reviews" ADD CONSTRAINT "reviews_buyer_id_fkey" FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."reviews" ADD CONSTRAINT "reviews_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."reviews" ADD CONSTRAINT "reviews_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."reviews" ADD CONSTRAINT "reviews_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."simulated_fp_ledger" ADD CONSTRAINT "simulated_fp_ledger_related_user_id_fkey" FOREIGN KEY (related_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."simulated_fp_ledger" ADD CONSTRAINT "simulated_fp_ledger_simulated_tx_id_fkey" FOREIGN KEY (simulated_tx_id) REFERENCES simulated_fp_transactions(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."simulated_fp_ledger" ADD CONSTRAINT "simulated_fp_ledger_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."simulated_fp_transactions" ADD CONSTRAINT "simulated_fp_transactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."user_insurance_selections" ADD CONSTRAINT "fk_insurance_product" FOREIGN KEY (insurance_product_id) REFERENCES insurance_product(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."user_insurance_selections" ADD CONSTRAINT "fk_user" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."users" ADD CONSTRAINT "users_inviter_id_fkey" FOREIGN KEY (inviter_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."users" ADD CONSTRAINT "users_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;

DROP TABLE IF EXISTS "insurance_order_detail";
CREATE VIEW "insurance_order_detail" AS SELECT io.id AS order_id,
    io.order_number,
    io.user_id AS buyer_user_id,
    u.username AS buyer_username,
    io.insurance_product_id,
    ip.short_title AS insurance_name,
    io.premium_amount,
    io.commission_pool,
    io.payment_method,
    io.finpoint_spent,
    cpd.recipient_user_id,
    ur.username AS recipient_username,
    cpd.recipient_role,
    cpd.upline_level,
    cpd.share_portion,
    cpd.amount,
    cpd.distributed_at
   FROM ((((insurance_orders io
     JOIN users u ON ((io.user_id = u.id)))
     JOIN insurance_product ip ON ((io.insurance_product_id = ip.id)))
     JOIN commission_pool_distribution cpd ON ((io.id = cpd.insurance_order_id)))
     JOIN users ur ON ((cpd.recipient_user_id = ur.id)))
  ORDER BY io.created_at DESC, cpd.upline_level;

DROP TABLE IF EXISTS "user_finpoint_summary";
CREATE VIEW "user_finpoint_summary" AS SELECT recipient_user_id,
    count(*) AS total_transactions,
    count(DISTINCT insurance_order_id) AS total_orders_involved,
    sum(
        CASE
            WHEN (amount > (0)::numeric) THEN amount
            ELSE (0)::numeric
        END) AS total_received,
    sum(
        CASE
            WHEN (amount < (0)::numeric) THEN abs(amount)
            ELSE (0)::numeric
        END) AS total_spent,
    sum(amount) AS current_finpoint,
    sum(
        CASE
            WHEN ((recipient_role)::text = 'buyer'::text) THEN amount
            ELSE (0)::numeric
        END) AS from_own_purchase,
    sum(
        CASE
            WHEN ((recipient_role)::text ~~ 'upline_%'::text) THEN amount
            ELSE (0)::numeric
        END) AS from_network,
    sum(
        CASE
            WHEN ((recipient_role)::text = 'system_root'::text) THEN amount
            ELSE (0)::numeric
        END) AS from_system
   FROM commission_pool_distribution
  GROUP BY recipient_user_id;

DROP TABLE IF EXISTS "v_active_users_acf";
CREATE VIEW "v_active_users_acf" AS SELECT id,
    world_id,
    username,
    run_number,
    parent_id,
    level,
    child_count,
    max_children,
    acf_accepting,
    own_finpoint,
    total_finpoint,
    created_at
   FROM users u
  WHERE (is_active = true)
  ORDER BY run_number;

DROP TABLE IF EXISTS "v_simulated_fp_summary";
CREATE VIEW "v_simulated_fp_summary" AS SELECT u.id AS user_id,
    u.world_id,
    u.username,
    count(DISTINCT sft.id) AS total_transactions,
    COALESCE(sum(
        CASE
            WHEN ((sfl.dr_cr)::text = 'DR'::text) THEN sfl.simulated_fp_amount
            ELSE (0)::numeric
        END), (0)::numeric) AS total_fp_earned,
    COALESCE(sum(
        CASE
            WHEN ((sfl.dr_cr)::text = 'CR'::text) THEN sfl.simulated_fp_amount
            ELSE (0)::numeric
        END), (0)::numeric) AS total_fp_spent,
    COALESCE(sum(
        CASE
            WHEN ((sfl.dr_cr)::text = 'DR'::text) THEN sfl.simulated_fp_amount
            ELSE (- sfl.simulated_fp_amount)
        END), (0)::numeric) AS net_fp_balance
   FROM ((users u
     LEFT JOIN simulated_fp_ledger sfl ON ((sfl.user_id = u.id)))
     LEFT JOIN simulated_fp_transactions sft ON ((sft.id = sfl.simulated_tx_id)))
  GROUP BY u.id, u.world_id, u.username
  ORDER BY COALESCE(sum(
        CASE
            WHEN ((sfl.dr_cr)::text = 'DR'::text) THEN sfl.simulated_fp_amount
            ELSE (- sfl.simulated_fp_amount)
        END), (0)::numeric) DESC;

DROP TABLE IF EXISTS "v_user_network_summary";
CREATE VIEW "v_user_network_summary" AS SELECT u.id,
    u.world_id,
    u.username,
    u.run_number,
    u.level,
    u.child_count,
    u.max_children,
    u.acf_accepting,
    count(DISTINCT r.referee_id) AS total_referrals,
    COALESCE(sum(e.amount_local), (0)::numeric) AS total_earnings
   FROM ((users u
     LEFT JOIN referrals r ON ((r.referrer_id = u.id)))
     LEFT JOIN earnings e ON (((e.user_id = u.id) AND ((e.status)::text = 'paid'::text))))
  GROUP BY u.id, u.world_id, u.username, u.run_number, u.level, u.child_count, u.max_children, u.acf_accepting
  ORDER BY u.run_number;

-- 2025-12-06 06:00:59 UTC
