# nekonata_core

nekonataの、nekonataによる、nekonataのためのライブラリ

## TL;DR

- 開発規則を読んでおいてください

## 開発規則

### 設計方針

- [Workspaces | Dart](https://dart.dev/tools/pub/workspaces)をもとに、monorepo形式を採用
- 特別な理由がない限り、パッケージに依存するパッケージのバージョンは指定しない
- 構造に困ったら、有名なmonorepoである[plus\_plugins](https://github.com/fluttercommunity/plus_plugins/tree/main)を参考

### 新規プロジェクト作成時

- [【Flutter3.27以降】マルチプロジェクトの作成│Flutter Salon](https://flutter.salon/dart/pub-workspaces/)を参考
- `nekonata_<package name>`のように、nekonataをprefixとして付与
