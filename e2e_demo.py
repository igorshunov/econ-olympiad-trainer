"""End-to-end demo для пользователя — headed mode, с паузами между шагами,
чтобы человек успел рассмотреть каждое действие."""
import os, time
os.environ['DISPLAY'] = ':0'
from playwright.sync_api import sync_playwright

URL = "http://localhost:8765"

def step(msg, pause=2.5):
    print(f"\n→ {msg}")
    time.sleep(pause)

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(
            channel='chrome',
            headless=False,
            args=['--window-size=1280,820']
        )
        ctx = browser.new_context(viewport={"width": 1280, "height": 800})
        page = ctx.new_page()
        page.set_default_timeout(8000)

        step("Шаг 1. Открываю приложение (страница логина)")
        page.goto(URL + "/index.html")
        page.wait_for_load_state("domcontentloaded")
        time.sleep(2)

        step("Шаг 2. Чищу IndexedDB чтобы был чистый старт")
        page.evaluate("""
          async () => {
            await indexedDB.deleteDatabase('econtrainer');
            localStorage.clear();
          }
        """)
        page.reload()
        time.sleep(2)

        step("Шаг 3. Захожу как гость")
        page.click("#guest-btn")
        page.wait_for_url("**/dashboard.html")
        time.sleep(2)

        backend = page.evaluate("Storage.backend")
        step(f"Шаг 4. Открылся дашборд. Storage backend = {backend}", 4)

        step("Шаг 5. Жму 'Следующая задача'")
        page.click("a.btn:has-text('Следующая задача')")
        page.wait_for_url("**/task.html")
        time.sleep(2)

        topic = page.text_content("#topic-tag")
        diff = page.text_content("#diff-tag")
        source = page.text_content("#source-tag")
        mastery = page.text_content("#mastery-tag")
        text_preview = (page.text_content("#task-text") or "")[:80]
        step(f"Шаг 6. Загрузилась задача: тема='{topic}', сложность={diff}, источник='{source}', mastery={mastery}", 4)
        step(f"     Условие начинается так: '{text_preview}...'", 1)

        step("Шаг 7. Жму 'Показать разбор' — увидим ответ + решение")
        page.click("#reveal-btn")
        time.sleep(3)

        step("Шаг 8. Появилась карточка self-feedback внизу. Жму 'Решил уверенно'")
        page.click("button[data-action='solved']")
        time.sleep(3)

        new_topic = page.text_content("#topic-tag")
        new_mastery = page.text_content("#mastery-tag")
        new_text = (page.text_content("#task-text") or "")[:80]
        step(f"Шаг 9. Перешли на новую задачу. тема='{new_topic}', mastery={new_mastery}", 3)
        step(f"     Новое условие: '{new_text}...'", 1)

        step("Шаг 10. Покажу как работает 'Слишком сложно' (понизит mastery)")
        page.click("#reveal-btn")
        time.sleep(2)
        page.click("button[data-action='too_hard']")
        time.sleep(3)
        after_topic = page.text_content("#topic-tag")
        after_mastery = page.text_content("#mastery-tag")
        step(f"     Темa после 'слишком сложно': '{after_topic}', mastery={after_mastery}", 3)

        step("Шаг 11. Открываю Прогресс — там должна быть история попыток")
        page.click("nav a:has-text('Прогресс')")
        page.wait_for_url("**/progress.html")
        time.sleep(3)

        rows = page.locator("#history-tbody tr").count()
        summary = page.text_content("#summary")
        step(f"     summary: {summary}", 1)
        step(f"     Записей в журнале: {rows}", 3)

        step("Шаг 12. Перезагружаю страницу — проверим что IndexedDB сохранил всё")
        page.reload()
        time.sleep(2)
        rows2 = page.locator("#history-tbody tr").count()
        step(f"     После перезагрузки записей: {rows2} {'✓ persistence работает!' if rows2 == rows else '✗ потерялись!'}", 4)

        step("Шаг 13. Открываю дашборд — проверим что граф знаний цветится по mastery")
        page.click("nav a:has-text('Граф знаний')")
        page.wait_for_url("**/dashboard.html")
        time.sleep(4)
        step("     Узел 'Базовые понятия экономики' должен быть не красным, потому что mastery вырос", 5)

        step("Шаг 14. На этом демо завершён. Закрываю браузер через 8 сек.")
        time.sleep(8)
        browser.close()

if __name__ == "__main__":
    main()
