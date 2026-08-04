-- A credencial fica no Vault e nunca no repositório. A operação deve criar o
-- segredo birthday_cron_secret antes desta agenda (ver docs/OPERACAO.md).
do $$
declare v_job bigint;
begin
  select jobid into v_job from cron.job where jobname='aniversarios-diario';
  if v_job is not null then perform cron.unschedule(v_job); end if;
end $$;

select cron.schedule('aniversarios-diario','0 12 * * *',$job$
  select net.http_post(
    url := 'https://lshjtlzlywipxtfwbxxe.supabase.co/functions/v1/aniversarios',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='birthday_cron_secret' limit 1)
    ),
    body := '{}'::jsonb
  );
$job$);
