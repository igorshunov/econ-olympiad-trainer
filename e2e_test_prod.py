"""End-to-end smoke test веб-приложения через Playwright."""
from playwright.sync_api import sync_playwright
import sys, time

URL = "https://webapp-xi-smoky-65.vercel.app"

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel='chrome', headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 900})
        page = context.new_page()
        page.set_default_timeout(8000)
        msgs = []
        page.on("console", lambda m: msgs.append(f"  [console.{m.type}] {m.text}"))
        page.on("pageerror", lambda e: msgs.append(f"  [PAGEERROR] {e}"))

        # 1) Login page
        print("STEP 1: open login")
        page.goto(URL + "/")
        page.wait_for_load_state("domcontentloaded")
        print("  url:", page.url)
        # Should be index.html (no user yet)
        assert 'webapp-xi-smoky' in page.url, f"expected index, got {page.url}"
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_01_login.png", full_page=True)

        # 2) Click guest
        print("STEP 2: click 'Продолжить как гость'")
        page.click("#guest-btn")
        page.wait_for_url("**/dashboard*", timeout=8000)
        page.wait_for_timeout(1500)  # let cytoscape settle
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_02_dashboard.png", full_page=True)
        print("  url:", page.url)

        # Check storage backend
        backend = page.evaluate("Storage.backend")
        print("  storage backend:", backend)

        # 3) Click "Next task"
        print("STEP 3: click 'Следующая задача'")
        page.click("a.btn:has-text('Следующая задача')")
        page.wait_for_url("**/task*")
        page.wait_for_timeout(800)
        # Should see task text
        task_text = page.text_content("#task-text")
        assert task_text and len(task_text) > 10, "task text not loaded"
        print("  task:", task_text[:80])
        # check tags
        topic = page.text_content("#topic-tag")
        diff = page.text_content("#diff-tag")
        mastery = page.text_content("#mastery-tag")
        print(f"  topic={topic!r}  diff={diff!r}  mastery={mastery!r}")
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_03_task.png", full_page=True)

        # 4) Click "Показать разбор"
        print("STEP 4: reveal solution")
        page.click("#reveal-btn")
        page.wait_for_timeout(400)
        exp = page.text_content(".explanation")
        assert exp and len(exp) > 5, "explanation missing"
        print("  solution preview:", exp[:100])
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_04_answered.png", full_page=True)

        # 6) Click "Решил уверенно"
        print("STEP 6: feedback 'solved'")
        page.click("button[data-action='solved']")
        page.wait_for_timeout(600)
        # New task should be loaded
        new_text = page.text_content("#task-text")
        assert new_text != task_text, f"task did not change after feedback: {new_text!r} vs {task_text!r}"
        new_topic = page.text_content("#topic-tag")
        new_mastery = page.text_content("#mastery-tag")
        print(f"  NEW task: topic={new_topic!r} mastery={new_mastery!r}")
        print(f"  preview:", new_text[:80])
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_05_next_task.png", full_page=True)

        # 7) Go to progress
        print("STEP 7: open progress")
        page.click("nav a:has-text('Прогресс')")
        page.wait_for_url("**/progress*")
        page.wait_for_timeout(800)
        summary = page.text_content("#summary")
        print("  summary:", summary)
        rows = page.locator("#history-tbody tr").count()
        print("  history rows:", rows)
        assert rows >= 1, "expected at least 1 row in history"
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_06_progress.png", full_page=True)

        # 8) Reload and check that storage persists
        print("STEP 8: reload to check IndexedDB persistence")
        page.reload()
        page.wait_for_timeout(800)
        rows2 = page.locator("#history-tbody tr").count()
        print("  history rows after reload:", rows2)
        assert rows2 == rows, "history did not persist after reload"

        # 9) Make a 'too_hard' feedback to verify upstream navigation
        print("STEP 9: try 'слишком сложно' branch")
        page.goto(URL + "/task.html")
        page.wait_for_timeout(800)
        before_topic = page.text_content("#topic-tag")
        page.click("#reveal-btn")
        page.wait_for_timeout(200)
        page.click("button[data-action='too_hard']")
        page.wait_for_timeout(600)
        after_topic = page.text_content("#topic-tag")
        print(f"  before={before_topic!r}  after={after_topic!r}")
        page.screenshot(path="/home/igor/study/diploma/docs/screenshots/prod_e2e_07_too_hard.png", full_page=True)

        # 10) Check mastery actually saved
        print("STEP 10: inspect IndexedDB content")
        mastery_state = page.evaluate("Storage.getMastery()")
        # evaluate returns a promise, awaited automatically? in playwright sync API it does.
        print("  mastery state:", mastery_state)
        history_len = page.evaluate("Storage.getHistory().then(h => h.length)")
        print("  history length:", history_len)

        print("\nCONSOLE / ERRORS:")
        for m in msgs[-40:]:
            print(m)
        print("\n✓ ALL CHECKS PASSED")
        browser.close()

if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print(f"\n✗ ASSERTION FAILED: {e}", file=sys.stderr); sys.exit(1)
    except Exception as e:
        print(f"\n✗ ERROR: {e}", file=sys.stderr); sys.exit(2)
