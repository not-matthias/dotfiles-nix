# Python Silent Bugs

## Mutable Default Arguments

```python
def append_to(element, to=[]):  # list created once at def-time
    to.append(element)
    return to
```

State accumulates across calls. Second call returns `[1, 2]`, not `[2]`. Fix: `to=None`, then `if to is None: to = []`.

## Late Binding Closures

```python
funcs = [lambda: i for i in range(3)]
[f() for f in funcs]  # [2, 2, 2] — not [0, 1, 2]
```

Closure captures the variable `i`, not its value. Fix: `lambda i=i: i`.

## Exception Handling

```python
except:           # catches KeyboardInterrupt and SystemExit — Ctrl-C stops working
except Exception:
    pass          # swallows all errors including your own bugs
```

Flag: bare `except`, `except Exception: pass` without logging. Catch specific exceptions.

## Iterator Exhaustion

```python
gen = (x * 2 for x in range(5))
list(gen)  # [0, 2, 4, 6, 8]
list(gen)  # [] — exhausted, no error
```

Generators are single-pass. Re-iterating yields nothing silently.

## Identity vs Equality

```python
a = 257; b = 257
a is b  # False — CPython only interns [-5, 256]
```

`is` tests object identity, not value. Use `==` for value comparison. `is` only for `None`/`True`/`False`.

## Float Precision

```python
0.1 + 0.2 == 0.3  # False (0.30000000000000004)
```

Use `math.isclose(a, b)` or `decimal.Decimal` for money.

## Threading / GIL

```python
counter += 1  # NOT atomic — LOAD / ADD / STORE can interleave
```

GIL releases between bytecodes. Two threads can read same value and lose updates. Use `threading.Lock`.

Threads give no speedup for CPU-bound work. Use `multiprocessing` instead.

## Circular Imports

```python
# module_a.py
from module_b import helper  # triggers full execution of module_b
# module_b.py
from module_a import data    # module_a half-initialized → AttributeError or None
```

Move imports inside functions or restructure to break cycles.

## Set Ordering

```python
list({1, 2, 3})  # could be [1, 3, 2] — implementation defined
```

Set order is never guaranteed (any Python version). Dict order guaranteed from 3.7+. Use `sorted()` when order matters.

## String Formatting Security

```python
# .format() with user-controlled template — data exfiltration
template = "{obj.__init__.__globals__[SECRET_KEY]}"
template.format(obj=config_object)  # leaks secrets via __globals__
```

Never use user input as a `.format()` template. Use parameterized queries for SQL. `string.Template.safe_substitute()` for user templates.
