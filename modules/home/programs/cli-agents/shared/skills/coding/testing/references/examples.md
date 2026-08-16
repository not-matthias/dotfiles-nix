# Worked Examples

## Shopping Cart: Derive Tests From the Contract

The implementation is hidden; begin with only the public contract.

### Contract

```rust
pub struct Cart { /* hidden */ }

impl Cart {
    pub fn new() -> Self;
    /// Quantity must be 1..=99
    pub fn add(&mut self, item_id: &str, price: f64, qty: u32) -> Result<()>;
    /// Errors if item not in cart
    pub fn remove(&mut self, item_id: &str) -> Result<()>;
    /// Always >= 0.0, includes discounts
    pub fn total(&self) -> f64;
    /// Single-use. Errors if invalid or already used.
    pub fn apply_discount(&mut self, code: &str) -> Result<()>;
}
```

### Bad: inspect storage and mirror arithmetic

```rust
#[test]
fn test_add() {
    let mut cart = Cart::new();
    cart.add("hat", 25.0, 1).unwrap();
    assert_eq!(cart.items.len(), 1);     // internal field
    assert_eq!(cart.items[0].qty, 1);    // internal field
}

#[test]
fn test_total() {
    let mut cart = Cart::new();
    cart.add("hat", 25.0, 2).unwrap();
    assert_eq!(cart.total(), 50.0);      // mirrors 25 * 2
}
```

The first test breaks if storage changes from `Vec` to `HashMap`. The second only tests obvious multiplication inferred from the implementation. Neither protects a non-obvious contract constraint.

### Good: test contract constraints

```rust
use rstest::rstest;

fn cart_with(item_id: &str, price: f64, qty: u32) -> Cart {
    let mut c = Cart::new();
    c.add(item_id, price, qty).unwrap();
    c
}

#[rstest]
#[case(0, true)]     // below range
#[case(1, false)]    // lower bound
#[case(99, false)]   // upper bound
#[case(100, true)]   // above range
fn add_rejects_invalid_quantity(
    #[case] qty: u32,
    #[case] should_err: bool,
) {
    let result = Cart::new().add("hat", 10.0, qty);
    assert_eq!(result.is_err(), should_err);
}

#[test]
fn remove_nonexistent_item_errors() {
    assert!(Cart::new().remove("nope").is_err());
}

#[test]
fn discount_code_is_single_use() {
    let mut cart = cart_with("hat", 100.0, 1);
    cart.apply_discount("SAVE10").unwrap();
    assert!(cart.apply_discount("SAVE10").is_err());
}

#[test]
fn total_never_negative_after_large_discount() {
    let mut cart = cart_with("hat", 5.0, 1);
    let _ = cart.apply_discount("HALF_OFF");
    assert!(cart.total() >= 0.0);
}
```

These four tests defend quantity boundaries, the missing-item error, a single-use invariant, and the non-negative-total invariant. The helper establishes the ordinary success path, so it does not need a separate test.

## Executable Detection: Parameterize Related Cases

When one behavior has many inputs, parameterize it. Separate positive and negative tests so the names state intent.

### Bad: one test per case

```rust
#[test]
fn basic_java_command() {
    assert!(command_has_executable("java -jar bench.jar", &["java"]));
}

#[test]
fn java_with_absolute_path() {
    assert!(command_has_executable("/usr/bin/java -jar bench.jar", &["java"]));
}

#[test]
fn java_with_env_prefix() {
    assert!(command_has_executable("FOO=bar java -jar bench.jar", &["java"]));
}

#[test]
fn gradle_chained_with_and() {
    assert!(command_has_executable("cd /app && gradle bench", &["gradle"]));
}

#[test]
fn javascript_must_not_match_java() {
    assert!(!command_has_executable("javascript-runtime run", &["java"]));
}

#[test]
fn javascript_path_must_not_match_java() {
    assert!(!command_has_executable("/home/user/javascript/run.sh", &["java"]));
}

#[test]
fn scargoship_must_not_match_cargo() {
    assert!(!command_has_executable("scargoship build", &["cargo"]));
}
```

This repeats setup and hides the positive-versus-negative distinction in `assert!`.

### Good: parameterized positive and negative behavior

```rust
use rstest::rstest;

#[rstest]
#[case("java -jar bench.jar", &["java"])]
#[case("/usr/bin/java -jar bench.jar", &["java"])]
#[case("FOO=bar java -jar bench.jar", &["java"])]
#[case("cd /app && gradle bench", &["gradle"])]
#[case("cat file | python script.py", &["python"])]
#[case("sudo java -jar bench.jar", &["java"])]
#[case("(cd /app && java -jar bench.jar)", &["java"])]
#[case("setup.sh; java -jar bench.jar", &["java"])]
#[case("try_first || java -jar bench.jar", &["java"])]
fn matches(#[case] command: &str, #[case] names: &[&str]) {
    assert!(command_has_executable(command, names));
}

#[rstest]
#[case("javascript-runtime run", &["java"])]
#[case("/home/user/javascript/run.sh", &["java"])]
#[case("scargoship build", &["cargo"])]
#[case("node index.js", &["gradle", "java", "maven", "mvn"])]
fn does_not_match(#[case] command: &str, #[case] names: &[&str]) {
    assert!(!command_has_executable(command, names));
}
```

Adding a case is one line, while `matches` and `does_not_match` make the expected behavior clear without reading each assertion.
