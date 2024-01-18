--changeset denis:1

create type email_template_type as enum ('generic', 'magic_link');

alter type email_template_type owner to firefly_dev_developer;

create type recipient_type as enum ('To', 'Cc', 'Bcc');

alter type recipient_type owner to firefly_dev_developer;

create table users
(
    id             uuid                  not null
        constraint users_pk
            primary key,
    email          varchar               not null,
    password       varchar               not null,
    salt           varchar,
    disabled       boolean default false not null,
    magic_link     varchar,
    last_logged_in timestamp,
    token          varchar
);

alter table users
    owner to firefly_dev_developer;

create unique index users_id_uindex
    on users (id);

create table default_email_templates
(
    id            uuid      not null
        constraint default_email_templates_pk
            primary key,
    body          varchar   not null,
    subject       varchar   not null,
    created_at    timestamp not null,
    template_type varchar   not null,
    default_keys  json      not null,
    styles        varchar
);

alter table default_email_templates
    owner to firefly_dev_developer;

create unique index default_email_templates_id_uindex
    on default_email_templates (id);

create table email_templates
(
    id                  uuid      not null
        constraint email_templates_pk
            primary key,
    default_template_id uuid      not null
        constraint email_templates_default_email_templates_id_fk
            references default_email_templates,
    template_keys       json      not null,
    created_at          timestamp not null
);

alter table email_templates
    owner to firefly_dev_developer;

create table queued_emails
(
    id              uuid                  not null
        constraint queued_emails_pk
            primary key,
    processed_at    timestamp,
    email_from      varchar               not null,
    send_at         timestamp             not null,
    template_id     uuid                  not null,
    has_attachments boolean default false not null,
    subject         varchar,
    created_at      timestamp             not null
);

alter table queued_emails
    owner to firefly_dev_developer;

create unique index queued_emails_id_uindex
    on queued_emails (id);

create table attachments
(
    id              uuid                    not null
        constraint attachments_pk
            primary key,
    queued_email_id uuid                    not null
        constraint attachments_queued_emails_id_fk
            references queued_emails,
    file_path       varchar                 not null,
    file_name       varchar                 not null,
    created_at      timestamp default now() not null
);

alter table attachments
    owner to firefly_dev_developer;

create unique index attachments_id_uindex
    on attachments (id);

create table recipients
(
    id              uuid                    not null
        constraint recipients_pk
            primary key,
    email_address   varchar                 not null,
    type            webtools.recipient_type,
    created_at      timestamp default now() not null,
    queued_email_id uuid                    not null
        constraint recipients_queued_emails_id_fk
            references queued_emails
);

alter table recipients
    owner to firefly_dev_developer;

create unique index recipients_id_uindex
    on recipients (id);

create table processed_emails
(
    id              uuid                    not null
        constraint processed_emails_pk
            primary key,
    created_at      timestamp default now() not null,
    body            varchar                 not null,
    email_from      varchar                 not null,
    email_to        varchar                 not null,
    sent_at         timestamp               not null,
    error_message   varchar,
    queued_email_id uuid                    not null
        constraint processed_emails_queued_emails_id_fk
            references queued_emails
);

alter table processed_emails
    owner to firefly_dev_developer;

create unique index processed_emails_id_uindex
    on processed_emails (id);

create table astra_export_keys
(
    id              uuid    not null
        constraint astra_export_keys_pk
            primary key,
    astra_key       varchar not null,
    import_job_step varchar not null,
    instance_type   varchar
);

alter table astra_export_keys
    owner to firefly_dev_developer;

create unique index astra_export_keys_id_uindex
    on astra_export_keys (id);

create table astra_import_log
(
    id                  uuid                                               not null
        constraint astra_import_log_pk
            primary key,
    customer_id         varchar                                            not null,
    created_at          timestamp default now()                            not null,
    completed_at        timestamp,
    updated_at          timestamp,
    import_state        varchar   default 'not_started'::character varying not null,
    import_step         varchar   default 'not_started'::character varying not null,
    export_data_link    varchar,
    export_data_expiry  timestamp,
    firefly_account_id  uuid,
    firefly_property_id uuid
);

alter table astra_import_log
    owner to firefly_dev_developer;

create unique index astra_import_log_id_uindex
    on astra_import_log (id);

create table permissions
(
    id         uuid                    not null
        constraint permissions_pk
            primary key,
    link       varchar                 not null,
    action     varchar                 not null,
    name       varchar,
    created_at timestamp default now() not null,
    deleted_at timestamp,
    updated_at timestamp
);

alter table permissions
    owner to firefly_dev_developer;

create unique index permissions_id_uindex
    on permissions (id);

create table roles
(
    id         uuid                    not null
        constraint roles_pk
            primary key,
    name       varchar,
    created_at timestamp default now() not null,
    deleted_at timestamp,
    updated_at timestamp,
    disabled   boolean   default false
);

alter table roles
    owner to firefly_dev_developer;

create unique index roles_id_uindex
    on roles (id);

create table role_permissions
(
    id            uuid                    not null
        constraint role_permissions_pk
            primary key,
    role_id       uuid                    not null
        constraint role_permissions_roles_id_fk
            references roles,
    permission_id uuid                    not null
        constraint role_permissions_permissions_id_fk
            references permissions,
    created_at    timestamp default now() not null,
    deleted_at    timestamp,
    updated_at    timestamp
);

alter table role_permissions
    owner to firefly_dev_developer;

create unique index role_permissions_id_uindex
    on role_permissions (id);

create table user_roles
(
    id         uuid                    not null
        constraint user_roles_pk
            primary key,
    role_id    uuid                    not null
        constraint user_roles_roles_id_fk
            references roles,
    user_id    uuid                    not null
        constraint user_roles_users_id_fk
            references users,
    created_at timestamp default now() not null,
    deleted_at timestamp,
    updated_at timestamp
);

alter table user_roles
    owner to firefly_dev_developer;

create unique index user_roles_id_uindex
    on user_roles (id);

create table astra_customers
(
    id               uuid    not null
        constraint astra_customers_pk
            primary key,
    customer_id      varchar not null,
    customer_name    varchar not null,
    details          json,
    customer_license varchar
);

alter table astra_customers
    owner to firefly_dev_developer;

create unique index astra_customers_id_uindex
    on astra_customers (id);

create table system_logs
(
    message          text,
    message_template text,
    level            varchar(50),
    raise_date       timestamp,
    exception        text,
    properties       jsonb,
    props_test       jsonb,
    machine_name     text,
    id               uuid not null
        constraint system_logs_pk
            primary key
);

alter table system_logs
    owner to firefly_dev_developer;

create unique index system_logs_id_uindex
    on system_logs (id);

create table api_keys
(
    id               uuid                    not null
        constraint api_keys_pk
            primary key,
    integration_name varchar                 not null,
    api_key          varchar                 not null,
    expiration_date  timestamp,
    created_at       timestamp default now() not null,
    updated_at       timestamp,
    deleted_at       timestamp
);

alter table api_keys
    owner to firefly_dev_developer;

create unique index api_keys_id_uindex
    on api_keys (id);

create table api_key_scopes
(
    id         uuid                    not null
        constraint api_key_scopes_pk
            primary key,
    api_key    uuid                    not null
        constraint api_key_scopes_api_keys_id_fk
            references api_keys,
    scope      varchar                 not null,
    created_at timestamp default now() not null,
    updated_at timestamp,
    deleted_at timestamp
);

alter table api_key_scopes
    owner to firefly_dev_developer;

create unique index api_key_scopes_id_uindex
    on api_key_scopes (id);

create table system_configuration
(
    id           uuid                    not null
        constraint system_configuration_pk
            primary key,
    config_key   varchar                 not null,
    config_value varchar                 not null,
    created_at   timestamp default now() not null,
    deleted_at   timestamp,
    updated_at   timestamp
);

alter table system_configuration
    owner to firefly_dev_developer;

create unique index system_configuration_id_uindex
    on system_configuration (id);

create table astra_imported_properties
(
    id                  uuid                    not null
        constraint astra_imported_properties_pk
            primary key,
    import_log_id       uuid                    not null,
    firefly_property_id uuid                    not null,
    created_at          timestamp default now() not null,
    updated_at          timestamp,
    astra_property_id   varchar                 not null
);

alter table astra_imported_properties
    owner to firefly_dev_developer;

create unique index astra_imported_properties_id_uindex
    on astra_imported_properties (id);

create table astra_import_key_progress
(
    id            uuid    not null
        constraint astra_import_key_progress_pk
            primary key,
    import_log_id uuid    not null
        constraint astra_import_key_progress_astra_import_log_id_fk
            references astra_import_log
            on delete cascade,
    key           varchar not null,
    unzipped_at   timestamp,
    raw_data      varchar,
    imported_at   timestamp,
    failed_at     timestamp
);

alter table astra_import_key_progress
    owner to firefly_dev_developer;

create unique index astra_import_key_progress_id_uindex
    on astra_import_key_progress (id);

create table astra_import_job_logs
(
    id                 uuid                    not null
        constraint astra_import_job_logs_pk
            primary key,
    import_log_id      uuid                    not null,
    import_progress_id uuid                    not null,
    batch_guid         uuid                    not null,
    created_at         timestamp default now() not null,
    astra_key          varchar                 not null,
    import_job_step    varchar                 not null,
    level              varchar(50),
    message            text,
    exception          text,
    properties         jsonb,
    machine_name       text
);

alter table astra_import_job_logs
    owner to firefly_dev_developer;

create unique index astra_import_job_logs_id_uindex
    on astra_import_job_logs (id);

create index astra_import_job_logs_created_at_index
    on astra_import_job_logs (created_at);

create index astra_import_job_logs_import_progress_id_index
    on astra_import_job_logs (import_progress_id);

create index astra_import_job_logs_import_log_id_index
    on astra_import_job_logs (import_log_id);

create table astra_import_imported
(
    id                  uuid                    not null
        constraint astra_import_imported_pk
            primary key,
    import_log_id       uuid                    not null,
    batch_guid          uuid                    not null,
    created_at          timestamp default now() not null,
    astra_key           varchar                 not null,
    astra_ref_id        varchar                 not null,
    import_job_step     varchar                 not null,
    import_job_step_sub varchar                 not null,
    firefly_property_id uuid                    not null
);

alter table astra_import_imported
    owner to firefly_dev_developer;

create index astra_import_imported_created_at_index
    on astra_import_imported (created_at);

create unique index astra_import_imported_index
    on astra_import_imported (id);

create index astra_import_imported_import_log_id_index
    on astra_import_imported (import_log_id);

create index astra_import_imported_astra_key_index
    on astra_import_imported (astra_key);

create index astra_import_imported_firefly_property_id_idx
    on astra_import_imported (firefly_property_id);

-- grant delete, insert, references, select, trigger, truncate, update on astra_import_imported to firefly_dev_owner_role;

-- grant delete, insert, select, update on astra_import_imported to firefly_dev_app_svc_role;

-- grant delete, insert, select, update on astra_import_imported to developer_role;

create view v_user_permissions(link, action, user_id, role_id, role_name, permission_id) as
SELECT p.link,
       p.action,
       u.id   AS user_id,
       r.id   AS role_id,
       r.name AS role_name,
       p.id   AS permission_id
FROM webtools.user_roles ur
         LEFT JOIN webtools.roles r ON ur.role_id = r.id
         LEFT JOIN webtools.users u ON ur.user_id = u.id
         LEFT JOIN webtools.role_permissions rp ON r.id = rp.role_id
         LEFT JOIN webtools.permissions p ON rp.permission_id = p.id
WHERE p.deleted_at IS NULL
  AND rp.deleted_at IS NULL
  AND ur.deleted_at IS NULL
  AND r.disabled = false;

alter table v_user_permissions
    owner to firefly_dev_developer;

create view v_api_scopes(id, integration_name, api_key, scope, expiration_date, scope_id) as
SELECT ak.id,
       ak.integration_name,
       ak.api_key,
       aks.scope,
       ak.expiration_date,
       aks.id AS scope_id
FROM webtools.api_key_scopes aks
         LEFT JOIN webtools.api_keys ak ON aks.api_key = ak.id
WHERE ak.deleted_at IS NULL
  AND aks.deleted_at IS NULL;

alter table v_api_scopes
    owner to firefly_dev_developer;

/* create procedure delete_astra_import(account_id uuid, property_id uuid, purgelog boolean)
    language sql
as
$$
delete from webtools.astra_import_log where firefly_account_id = CASE WHEN purgeLog = true THEN account_id ELSE gen_random_uuid() END;
    delete from webtools.astra_imported_properties where firefly_property_id = CASE WHEN purgeLog = true THEN property_id ELSE gen_random_uuid() END; ;

    set search_path = firefly_app;

    call firefly_app.delete_property(property_id);
    call firefly_app.delete_account(account_id);

    $$;*/

alter procedure delete_astra_import(uuid, uuid, boolean) owner to firefly_dev_developer;


