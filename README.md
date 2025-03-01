# nekonata_core

nekonataの、nekonataによる、nekonataのためのライブラリ

## TL;DR

- 開発規則を読んでおいてください

## 開発規則

### 設計方針

- very_good_analysisを採用
- packagesフォルダにパッケージ群を配置する
- [Workspaces | Dart](https://dart.dev/tools/pub/workspaces)をもとに、monorepo形式を採用
- 基本的にパッケージに依存するパッケージのバージョンは指定しない

### 新規プロジェクト作成時

- `nekonata_<package name>`のように、nekonataをprefixとして付与
- Dartのみであれば、`-t package`を指定
- AndroidとiOS固有の処理があれば、`-t plugin`を指定

## 参考サイト

- [【Flutter3.27以降】マルチプロジェクトの作成│Flutter Salon](https://flutter.salon/dart/pub-workspaces/)を参考
