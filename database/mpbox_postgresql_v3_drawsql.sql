CREATE TABLE "users"(
    "id" INTEGER NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "users" ADD PRIMARY KEY("id");
ALTER TABLE
    "users" ADD CONSTRAINT "users_email_unique" UNIQUE("email");
CREATE TABLE "roles"(
    "id" INTEGER NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "can_access_ai" BOOLEAN NOT NULL DEFAULT FALSE,
    "can_manage_accounts" BOOLEAN NOT NULL DEFAULT FALSE,
    "can_manage_roles" BOOLEAN NOT NULL DEFAULT FALSE,
    "can_edit_ai" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "roles" ADD PRIMARY KEY("id");
ALTER TABLE
    "roles" ADD CONSTRAINT "roles_name_unique" UNIQUE("name");
CREATE TABLE "user_roles"(
    "user_id" INTEGER NOT NULL,
    "role_id" INTEGER NOT NULL
);
ALTER TABLE
    "user_roles" ADD PRIMARY KEY("user_id", "role_id");
CREATE TABLE "ai_partners"(
    "id" INTEGER NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "description" TEXT NULL,
    "is_builtin" BOOLEAN NOT NULL DEFAULT FALSE,
    "is_enabled" BOOLEAN NOT NULL DEFAULT TRUE,
    "model_name" VARCHAR(100) NULL,
    "system_prompt" TEXT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "ai_partners" ADD PRIMARY KEY("id");
ALTER TABLE
    "ai_partners" ADD CONSTRAINT "ai_partners_name_unique" UNIQUE("name");
CREATE TABLE "role_ai_partners"(
    "role_id" INTEGER NOT NULL,
    "partner_id" INTEGER NOT NULL
);
ALTER TABLE
    "role_ai_partners" ADD PRIMARY KEY("role_id", "partner_id");
CREATE TABLE "knowledge_bases"(
    "id" INTEGER NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "description" TEXT NULL,
    "created_by" INTEGER NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "knowledge_bases" ADD PRIMARY KEY("id");
CREATE TABLE "role_kb_map"(
    "role_id" INTEGER NOT NULL,
    "kb_id" INTEGER NOT NULL
);
ALTER TABLE
    "role_kb_map" ADD PRIMARY KEY("role_id", "kb_id");
CREATE TABLE "partner_kb_map"(
    "partner_id" INTEGER NOT NULL,
    "kb_id" INTEGER NOT NULL
);
ALTER TABLE
    "partner_kb_map" ADD PRIMARY KEY("partner_id", "kb_id");
CREATE TABLE "kb_documents"(
    "id" INTEGER NOT NULL,
    "kb_id" INTEGER NOT NULL,
    "file_name" VARCHAR(500) NOT NULL,
    "file_size" BIGINT NOT NULL DEFAULT 0,
    "file_type" VARCHAR(50) NULL,
    "storage_path" VARCHAR(1000) NULL,
    "processing_status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "chunk_count" INTEGER NOT NULL DEFAULT 0,
    "uploaded_by" INTEGER NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "kb_documents" ADD PRIMARY KEY("id");
CREATE TABLE "kb_doc_chunks"(
    "id" INTEGER NOT NULL,
    "document_id" INTEGER NOT NULL,
    "chunk_index" INTEGER NOT NULL DEFAULT 0,
    "content" TEXT NOT NULL,
    "embedding" TEXT NULL,
    "token_count" INTEGER NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "kb_doc_chunks" ADD PRIMARY KEY("id");
CREATE TABLE "kb_tables"(
    "id" INTEGER NOT NULL,
    "kb_id" INTEGER NOT NULL,
    "table_name" VARCHAR(200) NOT NULL,
    "source" VARCHAR(50) NOT NULL DEFAULT 'custom',
    "created_by" INTEGER NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "kb_tables" ADD PRIMARY KEY("id");
CREATE TABLE "kb_table_columns"(
    "id" INTEGER NOT NULL,
    "table_id" INTEGER NOT NULL,
    "column_name" VARCHAR(200) NOT NULL,
    "column_type" VARCHAR(50) NOT NULL DEFAULT 'text',
    "column_order" INTEGER NOT NULL DEFAULT 0
);
ALTER TABLE
    "kb_table_columns" ADD PRIMARY KEY("id");
CREATE TABLE "kb_table_rows"(
    "id" INTEGER NOT NULL,
    "table_id" INTEGER NOT NULL,
    "row_data" JSON NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "kb_table_rows" ADD PRIMARY KEY("id");
CREATE TABLE "log_batches"(
    "id" INTEGER NOT NULL,
    "source_file" VARCHAR(1000) NOT NULL,
    "device_name" VARCHAR(255) NULL,
    "batch_date" DATE NOT NULL,
    "raw_log_count" INTEGER NOT NULL DEFAULT 0,
    "filtered_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL
);
ALTER TABLE
    "log_batches" ADD PRIMARY KEY("id");
CREATE TABLE "analysis_sessions"(
    "id" INTEGER NOT NULL,
    "partner_id" INTEGER NOT NULL,
    "analysis_date" DATE NOT NULL,
    "triggered_by" VARCHAR(50) NOT NULL DEFAULT 'schedule',
    "source_file" VARCHAR(1000) NULL,
    "status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "flash_status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "pro_status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "merge_status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "total_log_count" INTEGER NOT NULL DEFAULT 0,
    "event_count" INTEGER NOT NULL DEFAULT 0,
    "flash_token" INTEGER NULL,
    "pro_token" INTEGER NULL,
    "error_message" TEXT NULL,
    "started_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "completed_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "analysis_sessions" ADD PRIMARY KEY("id");
CREATE TABLE "session_batch_map"(
    "session_id" INTEGER NOT NULL,
    "batch_id" INTEGER NOT NULL
);
ALTER TABLE
    "session_batch_map" ADD PRIMARY KEY("session_id", "batch_id");
CREATE TABLE "flash_results"(
    "id" INTEGER NOT NULL,
    "session_id" INTEGER NOT NULL,
    "batch_id" INTEGER NULL,
    "chunk_index" INTEGER NOT NULL DEFAULT 0,
    "chunk_total" INTEGER NOT NULL DEFAULT 1,
    "result_json" JSON NOT NULL,
    "token_used" INTEGER NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL
);
ALTER TABLE
    "flash_results" ADD PRIMARY KEY("id");
CREATE TABLE "security_events"(
    "id" INTEGER NOT NULL,
    "session_id" INTEGER NULL,
    "title" VARCHAR(500) NOT NULL,
    "event_type" VARCHAR(100) NOT NULL,
    "star_rank" SMALLINT NOT NULL DEFAULT 1,
    "date_start" DATE NOT NULL,
    "date_end" DATE NULL,
    "detection_count" INTEGER NOT NULL DEFAULT 1,
    "affected_summary" VARCHAR(255) NULL,
    "affected_detail" TEXT NULL,
    "current_status" VARCHAR(50) NOT NULL DEFAULT 'pending',
    "description" TEXT NULL,
    "suggests" JSON NOT NULL DEFAULT '[]',
    "logs" JSON NOT NULL DEFAULT '[]',
    "ioc_list" JSON NOT NULL DEFAULT '[]',
    "mitre_tags" JSON NOT NULL DEFAULT '[]',
    "match_key" VARCHAR(500) NULL,
    "resolution" TEXT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "security_events" ADD PRIMARY KEY("id");
CREATE TABLE "event_history"(
    "id" INTEGER NOT NULL,
    "event_id" INTEGER NOT NULL,
    "user_id" INTEGER NULL,
    "note" TEXT NOT NULL,
    "status_change" VARCHAR(50) NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL
);
ALTER TABLE
    "event_history" ADD PRIMARY KEY("id");
ALTER TABLE
    "user_roles" ADD CONSTRAINT "user_roles_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");
ALTER TABLE
    "user_roles" ADD CONSTRAINT "user_roles_role_id_foreign" FOREIGN KEY("role_id") REFERENCES "roles"("id");
ALTER TABLE
    "role_ai_partners" ADD CONSTRAINT "role_ai_partners_role_id_foreign" FOREIGN KEY("role_id") REFERENCES "roles"("id");
ALTER TABLE
    "role_ai_partners" ADD CONSTRAINT "role_ai_partners_partner_id_foreign" FOREIGN KEY("partner_id") REFERENCES "ai_partners"("id");
ALTER TABLE
    "knowledge_bases" ADD CONSTRAINT "knowledge_bases_created_by_foreign" FOREIGN KEY("created_by") REFERENCES "users"("id");
ALTER TABLE
    "role_kb_map" ADD CONSTRAINT "role_kb_map_role_id_foreign" FOREIGN KEY("role_id") REFERENCES "roles"("id");
ALTER TABLE
    "role_kb_map" ADD CONSTRAINT "role_kb_map_kb_id_foreign" FOREIGN KEY("kb_id") REFERENCES "knowledge_bases"("id");
ALTER TABLE
    "partner_kb_map" ADD CONSTRAINT "partner_kb_map_partner_id_foreign" FOREIGN KEY("partner_id") REFERENCES "ai_partners"("id");
ALTER TABLE
    "partner_kb_map" ADD CONSTRAINT "partner_kb_map_kb_id_foreign" FOREIGN KEY("kb_id") REFERENCES "knowledge_bases"("id");
ALTER TABLE
    "kb_documents" ADD CONSTRAINT "kb_documents_kb_id_foreign" FOREIGN KEY("kb_id") REFERENCES "knowledge_bases"("id");
ALTER TABLE
    "kb_documents" ADD CONSTRAINT "kb_documents_uploaded_by_foreign" FOREIGN KEY("uploaded_by") REFERENCES "users"("id");
ALTER TABLE
    "kb_doc_chunks" ADD CONSTRAINT "kb_doc_chunks_document_id_foreign" FOREIGN KEY("document_id") REFERENCES "kb_documents"("id");
ALTER TABLE
    "kb_tables" ADD CONSTRAINT "kb_tables_kb_id_foreign" FOREIGN KEY("kb_id") REFERENCES "knowledge_bases"("id");
ALTER TABLE
    "kb_tables" ADD CONSTRAINT "kb_tables_created_by_foreign" FOREIGN KEY("created_by") REFERENCES "users"("id");
ALTER TABLE
    "kb_table_columns" ADD CONSTRAINT "kb_table_columns_table_id_foreign" FOREIGN KEY("table_id") REFERENCES "kb_tables"("id");
ALTER TABLE
    "kb_table_rows" ADD CONSTRAINT "kb_table_rows_table_id_foreign" FOREIGN KEY("table_id") REFERENCES "kb_tables"("id");
ALTER TABLE
    "analysis_sessions" ADD CONSTRAINT "analysis_sessions_partner_id_foreign" FOREIGN KEY("partner_id") REFERENCES "ai_partners"("id");
ALTER TABLE
    "session_batch_map" ADD CONSTRAINT "session_batch_map_session_id_foreign" FOREIGN KEY("session_id") REFERENCES "analysis_sessions"("id");
ALTER TABLE
    "session_batch_map" ADD CONSTRAINT "session_batch_map_batch_id_foreign" FOREIGN KEY("batch_id") REFERENCES "log_batches"("id");
ALTER TABLE
    "flash_results" ADD CONSTRAINT "flash_results_session_id_foreign" FOREIGN KEY("session_id") REFERENCES "analysis_sessions"("id");
ALTER TABLE
    "flash_results" ADD CONSTRAINT "flash_results_batch_id_foreign" FOREIGN KEY("batch_id") REFERENCES "log_batches"("id");
ALTER TABLE
    "security_events" ADD CONSTRAINT "security_events_session_id_foreign" FOREIGN KEY("session_id") REFERENCES "analysis_sessions"("id");
ALTER TABLE
    "event_history" ADD CONSTRAINT "event_history_event_id_foreign" FOREIGN KEY("event_id") REFERENCES "security_events"("id");
ALTER TABLE
    "event_history" ADD CONSTRAINT "event_history_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");
