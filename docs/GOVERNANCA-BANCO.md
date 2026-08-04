# Governança do Supabase compartilhado

Modox (`public`), 360social (`social`) e CT360 (`ct360`) usam o mesmo projeto Supabase.
Desde 4 de agosto de 2026, a fonte canônica das migrações fica em
`mevam-sistemas/ct360/supabase/migrations`, onde as 44 versões locais e remotas estão alinhadas.

Os SQLs deste repositório são cópias históricas do momento em que a funcionalidade nasceu. Para
qualquer mudança nova, abra uma migração no CT360, use nomes de schema explícitos e execute
`npm run db:verify` naquele repositório antes e depois da aplicação. Não usar o Dashboard para SQL
manual e não executar `supabase db push` a partir do Modox.
