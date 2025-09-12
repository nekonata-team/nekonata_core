# nekonata_core

nekonataの、nekonataによる、nekonataのためのライブラリ

## 開発規則

### 設計方針

- [Home | mise-en-place](https://mise.jdx.dev/)を採用
- `very_good_analysis`を採用
- `packages/`フォルダにパッケージ群を配置する
- [Workspaces | Dart](https://dart.dev/tools/pub/workspaces)によるmonorepo形式
- 基本的にパッケージに依存するパッケージのバージョンは指定しない

### 新規プロジェクト作成時

1. miseのセットアップ

    トップレベルのディレクトリで以下のコマンドを実行

    ```bash
    mise trust

    mise install
    ```

2. Flutterのコマンドで作成

    ```bash
    cd packages

    # Dart, Flutterのみであれば、-t packageを指定
    flutter create -t package nekonata_<package name>

    # Swift, Kotlinのコードが必要であれば、-t pluginを指定
    # プラットフォーム固有の処理を書くためのテンプレートが生成される
    flutter create -t plugin --platforms=ios,android nekonata_<package name>
    ```

3. 各パッケージの`pubspec.yaml`に`resolution: workspace`を追加

    ```yaml
    name: nekonata_map
    description: "A new Flutter plugin project."
    version: 0.0.1

    # here for monorepo
    resolution: workspace
    ```

4. ルートの`pubspec.yaml`に各パッケージを追加

    ```yaml
    workspace:
        - packages/xxx
        - ...
        - packages/nekonata_<package name> # here
    ```
