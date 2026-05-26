"""
Зачёт по МДК.01.04 «Системное программирование» (преп. Красиков А.В.).
Студент: Горшунов Игорь Станиславович, группа 15.ИСиП.23.О-ЗФ.С.1.ХК.

5 задач из README2.md. Каждая решена и снабжена inline-doctests,
которые можно прогнать так:
    python -m doctest solutions.py -v
Также внизу — простой runner с примерами из условия.
"""

from typing import List, Iterable


# ─── Задача 1 ────────────────────────────────────────────────────────────────
def maxTriSum(arr: List[int]) -> int:
    """
    Максимальная сумма трёх НЕПОВТОРЯЮЩИХСЯ элементов массива.
    Дубликаты учитываются только один раз (по условию: "при суммировании
    они не учитываются" — то есть набор уникальных значений).

    >>> maxTriSum([3, 2, 6, 8, 2, 3])
    17
    >>> maxTriSum([2, 1, 8, 0, 6, 4, 8, 6, 2, 4])
    18
    >>> maxTriSum([-7, 12, -7, 29, -5, 0, -7, 0, 0, 29])
    41
    """
    unique_sorted = sorted(set(arr), reverse=True)
    return sum(unique_sorted[:3])


# ─── Задача 2 ────────────────────────────────────────────────────────────────
def count_singles(text: str) -> int:
    """
    Количество одиночных букв в строке.
    Одиночной считается буква, которая:
      • встречается во всей строке ровно один раз (без учёта регистра);
      • не имеет в строке соседей по алфавиту (буквы ±1 от неё).
    Учитываются только латинские буквы a-z.

    >>> count_singles("ad")
    2
    >>> count_singles("abc")
    0
    >>> count_singles("Hello, World!")
    3
    >>> count_singles("A-dA")
    1
    >>> count_singles("zz")
    0
    """
    letters = [c for c in text.lower() if c.isascii() and c.isalpha()]
    present = set(letters)
    counts: dict = {}
    for c in letters:
        counts[c] = counts.get(c, 0) + 1

    result = 0
    for letter, n in counts.items():
        if n != 1:
            continue
        left  = chr(ord(letter) - 1) if letter > 'a' else None
        right = chr(ord(letter) + 1) if letter < 'z' else None
        has_neighbour = (left in present) or (right in present)
        if not has_neighbour:
            result += 1
    return result


# ─── Задача 3 ────────────────────────────────────────────────────────────────
def jumping(n: int) -> str:
    """
    Прыгающее число: соседние цифры отличаются ровно на 1.
    Разница 9 и 0 НЕ считается за 1. Однозначные числа — всегда прыгающие.

    >>> jumping(9)
    'Jumping!!'
    >>> jumping(79)
    'Not!!'
    >>> jumping(23)
    'Jumping!!'
    >>> jumping(556847)
    'Not!!'
    >>> jumping(4343456)
    'Jumping!!'
    >>> jumping(89098)
    'Not!!'
    >>> jumping(32)
    'Jumping!!'
    """
    s = str(n)
    if len(s) == 1:
        return "Jumping!!"
    for i in range(len(s) - 1):
        if abs(int(s[i]) - int(s[i + 1])) != 1:
            return "Not!!"
    return "Jumping!!"


# ─── Задача 4 ────────────────────────────────────────────────────────────────
def compress_images(directory: dict) -> dict:
    """
    Принимает «директорию» (структуру dict-like):
      {filename: {"size": int, ...}, ...}
    Находит все файлы .jpg и уменьшает их `size` в 2 раза (целочисленное деление).
    Возвращает обновлённую директорию (in-place + return).

    >>> d = {
    ...     "avatar.jpg": {"size": 100, "type": "image"},
    ...     "photo.jpg":  {"size": 150, "type": "image"},
    ...     "notes.txt":  {"size": 200},
    ... }
    >>> result = compress_images(d)
    >>> result["avatar.jpg"]["size"]
    50
    >>> result["photo.jpg"]["size"]
    75
    >>> result["notes.txt"]["size"]
    200
    >>> result["avatar.jpg"]["type"]
    'image'
    """
    for name, meta in directory.items():
        if name.lower().endswith(".jpg") and isinstance(meta, dict) and "size" in meta:
            meta["size"] = meta["size"] // 2
    return directory


# ─── Задача 5 ────────────────────────────────────────────────────────────────
class Menu:
    """
    Экран выбора с курсором, способным двигаться вправо/влево с циклическим
    переходом через границы списка. Курсор стартует с индекса 0.
    display() возвращает строковое представление списка, где выбранный
    элемент обёрнут в квадратные скобки.

    >>> m = Menu([1, 2, 3])
    >>> m.display()
    '[[1], 2, 3]'
    >>> m.to_the_right()
    >>> m.display()
    '[1, [2], 3]'
    >>> m.to_the_right()
    >>> m.display()
    '[1, 2, [3]]'
    >>> m.to_the_right()  # циклический переход
    >>> m.display()
    '[[1], 2, 3]'
    >>> m.to_the_left()
    >>> m.display()
    '[1, 2, [3]]'
    >>> Menu(['a', 'b']).display()
    '[[a], b]'
    """

    def __init__(self, items: Iterable):
        self.items = list(items)
        self.cursor = 0

    def display(self) -> str:
        parts = []
        for i, item in enumerate(self.items):
            if i == self.cursor:
                parts.append(f"[{item}]")
            else:
                parts.append(str(item))
        return "[" + ", ".join(parts) + "]"

    def to_the_right(self) -> None:
        if self.items:
            self.cursor = (self.cursor + 1) % len(self.items)

    def to_the_left(self) -> None:
        if self.items:
            self.cursor = (self.cursor - 1) % len(self.items)


# ─── Самопроверка ────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=== Задача 1: maxTriSum ===")
    for arr, expected in [
        ([3, 2, 6, 8, 2, 3], 17),
        ([2, 1, 8, 0, 6, 4, 8, 6, 2, 4], 18),
        ([-7, 12, -7, 29, -5, 0, -7, 0, 0, 29], 41),
    ]:
        got = maxTriSum(arr)
        print(f"  maxTriSum({arr}) = {got}   expected {expected}   {'OK' if got==expected else 'FAIL'}")

    print("\n=== Задача 2: count_singles ===")
    for s, expected in [
        ("ad", 2), ("abc", 0), ("Hello, World!", 3),
        ("A-dA", 1), ("zz", 0),
    ]:
        got = count_singles(s)
        print(f"  count_singles({s!r}) = {got}   expected {expected}   {'OK' if got==expected else 'FAIL'}")

    print("\n=== Задача 3: jumping ===")
    for n, expected in [
        (9, "Jumping!!"), (79, "Not!!"), (23, "Jumping!!"),
        (556847, "Not!!"), (4343456, "Jumping!!"),
        (89098, "Not!!"), (32, "Jumping!!"),
    ]:
        got = jumping(n)
        print(f"  jumping({n}) = {got!r}   expected {expected!r}   {'OK' if got==expected else 'FAIL'}")

    print("\n=== Задача 4: compress_images ===")
    d = {
        "avatar.jpg": {"size": 100},
        "photo.jpg":  {"size": 150},
        "notes.txt":  {"size": 200},
    }
    compress_images(d)
    expected = {"avatar.jpg": 50, "photo.jpg": 75, "notes.txt": 200}
    for k, v in expected.items():
        got = d[k]["size"]
        print(f"  {k}.size = {got}   expected {v}   {'OK' if got==v else 'FAIL'}")

    print("\n=== Задача 5: Menu ===")
    m = Menu([1, 2, 3])
    print(f"  initial:     {m.display()}   expected '[[1], 2, 3]'")
    m.to_the_right()
    print(f"  after right: {m.display()}   expected '[1, [2], 3]'")
    m.to_the_right(); m.to_the_right()
    print(f"  after right×2 more (cycle): {m.display()}   expected '[[1], 2, 3]'")
    m.to_the_left()
    print(f"  after left (cycle back):    {m.display()}   expected '[1, 2, [3]]'")

    print("\n--- Полные doctest-тесты ---")
    import doctest
    res = doctest.testmod(verbose=False)
    print(f"  attempted: {res.attempted}, failed: {res.failed}")
