# nekonata_firestore

`nekonata_firestore` は、Cloud Firestore の操作を簡単にするための汎用的なリポジトリクラスを提供するパッケージです。

少しだけ記述量を減らすことができます。

## 機能

- 型安全な Firestore データ操作
- ドキュメントの取得 (`get`)
- ドキュメントの作成・上書き (`set`)
- ドキュメントの追加 (`add`)
- ドキュメントの削除 (`delete`)
- フィールドの更新 (`updateFields`)
- ドキュメントの一覧取得 (`getAll`)
- ドキュメントの変更を監視するストリーム (`stream`)

## 例

`test/nekonata_firestore_test.dart` を参照してください。
