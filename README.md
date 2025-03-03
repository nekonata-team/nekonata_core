# nekonata_core

nekonataの、nekonataによる、nekonataのためのライブラリ

## TL;DR

- 開発規則は少なくとも読んでおいてください

## 開発規則

READMEはできるだけ簡潔に書く

### 設計方針

- `very_good_analysis`を採用
- `packages/`フォルダにパッケージ群を配置する
- [Workspaces | Dart](https://dart.dev/tools/pub/workspaces)をもとに、monorepo形式を採用
- 基本的にパッケージに依存するパッケージのバージョンは指定しない

### 新規プロジェクト作成時

1. Flutterのコマンドで作成

    ```bash
    cd packages

    # Dart, Flutterのみであれば、-t packageを指定
    flutter create -t package --platforms=ios,android nekonata_<package name>

    # Swift, Kotlinのコードが必要であれば、-t pluginを指定
    # プラットフォーム固有の処理を書くためのテンプレートが生成される
    flutter create -t plugin --platforms=ios,android nekonata_<package name>
    ```

2. `pubspec.yaml`に`resolution: workspace`を追加

    ```yaml
    name: nekonata_map
    description: "A new Flutter plugin project."
    version: 0.0.1

    # here for monorepo
    resolution: workspace
    ```

### READMEのテンプレート

```md
# nekonata_xxx

abstract for project

## Getting Started

xxx

## How to Use

Check example app.

xxx

## Setup

### iOS

xxx

### Android

xxx

## Limitation

- xxx

```

## 参考サイト

- [【Flutter3.27以降】マルチプロジェクトの作成│Flutter Salon](https://flutter.salon/dart/pub-workspaces/)を参考
