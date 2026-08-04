-- Fotos privadas de perfil do MODOX. O navegador gera JPEG com até ~320 KB;
-- o bucket mantém uma margem técnica de 512 KB.

update storage.buckets
set file_size_limit = 524288,
    allowed_mime_types = array['image/jpeg','image/webp']
where id = 'fotos';

create or replace function public.pode_ver_foto_perfil(caminho text)
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select exists (
    select 1
    from pessoas alvo
    where alvo.foto_url = caminho
      and (
        alvo.id = pessoa_atual()
        or exists (
          select 1
          from vinculos va
          join vinculos leitor on leitor.escola_id = va.escola_id
          where va.pessoa_id = alvo.id
            and va.ativo
            and leitor.pessoa_id = pessoa_atual()
            and leitor.ativo
            and leitor.papel in ('professor','gestor','admin')
        )
      )
  )
$function$;

revoke all on function public.pode_ver_foto_perfil(text) from public, anon;
grant execute on function public.pode_ver_foto_perfil(text) to authenticated, service_role;

drop policy if exists modox_perfil_inserir on storage.objects;
create policy modox_perfil_inserir on storage.objects
for insert to authenticated
with check (
  bucket_id = 'fotos'
  and (
    ((storage.foldername(name))[1] = 'perfis'
      and (storage.foldername(name))[2] = public.pessoa_atual()::text)
    or
    ((storage.foldername(name))[1] = 'inscricoes'
      and (storage.foldername(name))[2] = auth.uid()::text)
  )
);

drop policy if exists modox_perfil_ler on storage.objects;
create policy modox_perfil_ler on storage.objects
for select to authenticated
using (bucket_id = 'fotos' and public.pode_ver_foto_perfil(name));

drop policy if exists modox_perfil_atualizar on storage.objects;
create policy modox_perfil_atualizar on storage.objects
for update to authenticated
using (
  bucket_id = 'fotos'
  and (storage.foldername(name))[1] = 'perfis'
  and (storage.foldername(name))[2] = public.pessoa_atual()::text
)
with check (
  bucket_id = 'fotos'
  and (storage.foldername(name))[1] = 'perfis'
  and (storage.foldername(name))[2] = public.pessoa_atual()::text
);

drop policy if exists modox_perfil_remover on storage.objects;
create policy modox_perfil_remover on storage.objects
for delete to authenticated
using (
  bucket_id = 'fotos'
  and (storage.foldername(name))[1] = 'perfis'
  and (storage.foldername(name))[2] = public.pessoa_atual()::text
);
