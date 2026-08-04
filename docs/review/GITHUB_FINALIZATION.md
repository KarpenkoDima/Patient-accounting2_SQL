# Финальное оформление GitHub

## Итоговое назначение

Репозиторий является замороженным архивом старой SQL Server-базы.
Он не используется для дальнейшей разработки.

## Рекомендуемые параметры

- **Имя:** `patient-accounting2-legacy-sql`
- **Description:** `Archived SQL Server schema and stored procedures from the legacy Patient-accounting2 project. Not maintained; not production-ready.`
- **Topics:** `legacy`, `sql-server`, `t-sql`, `ef-core`, `medical-domain`, `archive`
- **Default branch:** `main`
- **Issues:** выключить
- **Discussions:** выключить
- **Wiki:** выключить
- **Projects:** выключить
- **Repository visibility:** оставить текущую
- **Archive repository:** включить после завершения действий ниже

## Ветки

Оставить только:

```text
main
```

Удалить:

```text
master
Fix/CriticalBug
claude/ef-core-setup-guide-GziJY
```

Ветка `Fix/CriticalBug` уже объединена. Уникальный ADR-документ из ветки Claude
сохранён в `docs/legacy/EF_Core_Architecture_Decisions_UNVERIFIED.md`.

## Последовательность действий

```bash
git push -u origin main
git push origin legacy-final-2026-08-04
```

Затем в GitHub:

1. `Settings` → `Branches` → изменить default branch на `main`.
2. При желании переименовать репозиторий в `patient-accounting2-legacy-sql`.
3. Установить description и topics из этого документа.
4. Выключить Issues, Projects, Wiki и Discussions.

После смены default branch:

```bash
git push origin --delete master
git push origin --delete Fix/CriticalBug
git push origin --delete claude/ef-core-setup-guide-GziJY
```

Последнее действие:

```text
Settings → General → Danger Zone → Archive this repository
```

## Чего не делать

- не создавать roadmap;
- не заводить задачи на исправление legacy-кода;
- не добавлять CI ради архива;
- не объявлять SQL-код production-ready;
- не использовать этот репозиторий как основу нового приложения;
- не переносить сюда новые EF Core-примеры.
