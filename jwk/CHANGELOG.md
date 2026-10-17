## 0.2.5

* Use standard `oct` key type, string-list `keyOps`, and certificate-chain
  `List<List<int>>` for `x5c`. Certificate JSON uses standard base64.
  Legacy JSON `OCT`, string `key_ops`, and single-string `x5c` are accepted on
  input and normalized to the standard representation on output.
* Include all key material in content equality and preserve `cty`/`keyOps`
  through JSON and builder conversions.
* Update dependencies and require Dart 3.11 or later.

* Improves dependency constraints.

## 0.2.4
* Improves documentation.

## 0.2.3
* Raises Dart SDK minimum to 3.1.0.

## 0.2.2

* Adds p256k support ([#135](https://github.com/wanwenfeng4798/cryptography/pull/135)).
* Fixes a padding issue ([#134](https://github.com/wanwenfeng4798/cryptography/pull/134)).

## 0.2.1

* Improves documentation.

## 0.2.0

* Fixes various bugs.

## 0.1.1

* Updates dependency constraints and linting rules.

## 0.1.0

* Finishes null safety migration.

## 0.1.0-nullsafety.1

* Fixes SDK and dependency constraints.

## 0.1.0-nullsafety.0

  * Initial version.
