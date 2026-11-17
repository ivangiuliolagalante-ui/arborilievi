-- ArboRilievi Cloud - Comune di Noicattaro - schema iniziale
-- Eseguire una sola volta nel SQL Editor di Supabase di un progetto NUOVO.
-- ATTENZIONE: le policy consentono lettura al Comune e scrittura solo a rilevatori/amministratori.

create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'viewer' check (role in ('viewer','surveyor','admin')),
  qualification text not null default '',
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create or replace function public.app_role() returns text language sql stable security definer set search_path = '' as $$
  select p.role from public.profiles p where p.id = (select auth.uid()) and p.enabled = true limit 1
$$;

create table public.areas (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  kind text not null,
  istat text not null,
  usage_level text not null check (usage_level in ('Bassa','Media','Alta')),
  scope text not null check (scope in ('Urbano','Extraurbano')),
  managed_by text not null,
  management_start date not null,
  management_end date,
  is_fictitious boolean not null default false,
  geom jsonb, -- GeoJSON polygon WGS84; convertire/validare in GIS prima della consegna EPSG:7792
  area_m2 numeric,
  photo_path text,
  surveyor_id uuid references auth.users(id),
  surveyed_at date not null,
  notes text not null default '',
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.linear_elements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  area_code text not null references public.areas(code),
  kind text not null check(kind in ('Filare','Siepe','Bordura','Altro')),
  geom jsonb, -- GeoJSON LineString WGS84
  length_m numeric,
  width_m numeric,
  height_m numeric,
  species text not null default '',
  condition text not null check (condition in ('Buone','Discrete','Scarse','Pessime')),
  missing_extent text not null default '',
  surveyor_id uuid references auth.users(id),
  surveyed_at date not null,
  notes text not null default '',
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.trees (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  area_code text not null references public.areas(code),
  linear_code text references public.linear_elements(code),
  latitude double precision,
  longitude double precision,
  gps_accuracy_m numeric,
  position_method text not null default 'GPS smartphone',
  management_start date not null,
  management_end date,
  end_cause text,
  scientific_name text not null,
  cultivar text,
  common_name text,
  status text not null check(status in ('Pianta viva','Pianta morta','Ceppaia','Posto d’impianto libero')),
  trunk_diameter_cm numeric,
  trunk_count integer,
  height_m numeric,
  palm_stipe_height_m numeric,
  canopy_diameter_m numeric,
  development text not null check(development in ('Nuovo impianto','Giovane','Adulta','Senescente')),
  protection text not null,
  protection_notes text,
  vegetative_condition text not null check(vegetative_condition in ('Buone','Discrete','Scarse','Pessime')),
  phytosanitary text not null,
  structural_defects text[] not null default '{}',
  target_type text not null,
  target_frequency text not null check(target_frequency in ('Bassa','Media','Alta')),
  interferences text[] not null default '{}',
  failure_class text check(failure_class in ('A','B','C','C-D','D')),
  proposed_action text not null,
  action_priority text not null check(action_priority in ('Urgente','Alta','Ordinaria')),
  photo_paths text[] not null default '{}',
  surveyor_id uuid references auth.users(id),
  surveyor_qualification text not null,
  surveyed_at date not null,
  notes text not null default '',
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gps_pair check ((latitude is null and longitude is null) or (latitude between -90 and 90 and longitude between -180 and 180)),
  constraint status_diameter check (trunk_diameter_cm is null or trunk_diameter_cm >= 0)
);

-- Profilo inserito alla creazione utente: inizialmente viewer. Ruoli privilegiati solo via SQL Editor.
create or replace function public.on_auth_user_created() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, display_name, role)
  values(new.id, coalesce(new.raw_user_meta_data->>'display_name', new.email, ''), 'viewer')
  on conflict (id) do nothing;
  return new;
end;
$$;
create trigger trg_user_profile after insert on auth.users for each row execute function public.on_auth_user_created();

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
create trigger areas_touch before update on public.areas for each row execute function public.touch_updated_at();
create trigger linear_touch before update on public.linear_elements for each row execute function public.touch_updated_at();
create trigger trees_touch before update on public.trees for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.areas enable row level security;
alter table public.linear_elements enable row level security;
alter table public.trees enable row level security;

create policy "profile own read" on public.profiles for select to authenticated using (id = (select auth.uid()) or public.app_role() = 'admin');
-- Nessun update/insert/delete client-side dei profili: l'admin configura ruoli dal SQL Editor.

create policy "areas read" on public.areas for select to authenticated using (public.app_role() in ('viewer','surveyor','admin'));
create policy "areas create" on public.areas for insert to authenticated with check (public.app_role() in ('surveyor','admin') and created_by=(select auth.uid()));
create policy "areas update" on public.areas for update to authenticated using (public.app_role() in ('surveyor','admin')) with check (public.app_role() in ('surveyor','admin'));
create policy "linear read" on public.linear_elements for select to authenticated using (public.app_role() in ('viewer','surveyor','admin'));
create policy "linear create" on public.linear_elements for insert to authenticated with check (public.app_role() in ('surveyor','admin') and created_by=(select auth.uid()));
create policy "linear update" on public.linear_elements for update to authenticated using (public.app_role() in ('surveyor','admin')) with check (public.app_role() in ('surveyor','admin'));
create policy "trees read" on public.trees for select to authenticated using (public.app_role() in ('viewer','surveyor','admin'));
create policy "trees create" on public.trees for insert to authenticated with check (public.app_role() in ('surveyor','admin') and created_by=(select auth.uid()));
create policy "trees update" on public.trees for update to authenticated using (public.app_role() in ('surveyor','admin')) with check (public.app_role() in ('surveyor','admin'));
-- Non concediamo DELETE: gli abbattuti e le aree dismesse mantengono la storia.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('arborei-private','arborei-private',false,10485760,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "photos read" on storage.objects for select to authenticated using (
  bucket_id='arborei-private' and public.app_role() in ('viewer','surveyor','admin')
);
create policy "photos upload" on storage.objects for insert to authenticated with check (
  bucket_id='arborei-private' and public.app_role() in ('surveyor','admin')
);
-- Niente delete o update foto dal client: archiviazione storica.

-- DOPO aver creato gli utenti da Authentication > Users, promuoverli manualmente:
-- update public.profiles set role='admin', display_name='Responsabile', qualification='...' where id='UUID_UTENTE';
-- update public.profiles set role='surveyor', display_name='Rilevatore 1', qualification='...' where id='UUID_UTENTE';
-- update public.profiles set role='viewer', display_name='Comune / DEC' where id='UUID_UTENTE';
-- NOTA: auth utenti creati prima di eseguire schema.sql non ricevono profilo: inserirlo manualmente.
