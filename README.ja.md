# Manufacturing as Code PoC：GitHub Copilot ディスプレイスタンド

## 概要

このリポジトリは、3Dプリントされるハードウェア成果物をソフトウェア成果物として扱うための Manufacturing as Code 実験です。設計ソースは OpenSCAD で記述し、Git で管理し、生成パイプラインを通じて STL、PNG、Bambu のスライス出力、製造レポートを作成します。

現在の実装は、GitHub Copilot フィギュアを置くための小型のディスプレイスタンドです。公式の GitHub Copilot 3D モデルそのものは変更せず、別途スタンドを作成する形で、フィギュアを展示する目的に特化しています。

## 設計思想

- 形状を OpenSCAD のソースコードとして表現する
- 重要な寸法はマジックナンバーではなく名前付き変数で定義する
- OpenSCAD のモジュールとパラメータ群で設計を整理する
- 生成物とソースモデルを分離して管理する
- 視覚的な複雑さよりも再現性とレビュー性を優先する

## リポジトリ構成

```text
HardwareDevOps/
├── README.md
├── AGENTS.md
├── LICENSE
├── src/
│   └── copilot-stand.scad
├── scripts/
│   ├── build-model.sh
│   ├── generate-manufacturing-report.py
│   ├── validate-stand.py
│   └── ...
├── toolchain/
│   └── Dockerfile
├── profiles/
│   ├── machine/
│   ├── process/
│   └── filament/
├── tests/
│   └── test_manufacturing_report.py
├── artifacts/
│   └── generated build outputs
├── reports/
│   └── generated manufacturing reports
├── docs/
│   ├── requirements.md
│   └── design-decisions.md
└── .github/
    └── workflows/
        └── build-model.yml
```

## 現在の生成パイプライン

このリポジトリは、ホスト環境に直接 Bambu Studio や OpenSCAD を入れるのではなく、固定された Linux ツールチェーンイメージを使う構成です。再現性のために Linux 環境を明示的に固定しています。

### Linux が必要な理由

製造パイプラインは意図的に Linux 専用です。非 Linux 環境で実行すると、ホスト依存のアプリケーション構成や AppImage のレイアウトに引きずられずに、明確に失敗するようにしています。

これは以下の問題を避けるためです。

- 開発者ごとの差異
- macOS での実行差異
- Linux 専用スライサーの実行要件
- Bambu Studio AppImage のライブラリ依存やレイアウト差異

### ローカルでの標準実行

このリポジトリは `linux/amd64` を明示的に対象にしており、Apple Silicon の Mac では `arm64` に引っ張られて不一致になる可能性があるため、Docker Buildx でプラットフォームを固定しています。

```bash
docker buildx build --platform linux/amd64 --load -t hardware-devops-toolchain:bambu-studio toolchain/

docker run --rm --platform linux/amd64 \
  -v "$PWD:/workspace" \
  -w /workspace \
  hardware-devops-toolchain:bambu-studio \
  bash scripts/build-model.sh
```

このビルドスクリプトはコンテナ内で以下を実行します。

1. Linux 環境であることを検証する
2. OpenSCAD と Bambu CLI の存在を確認する
3. リポジトリ管理の Bambu プロファイルディレクトリを確認する
4. OpenSCAD から STL を生成する
5. PNG プレビュー画像を生成する
6. ヘッドレスで Bambu へ STL を渡し、スライスと出力を行う
7. 生成された G-code または 3MF を特定する
8. スライサー出力から製造レポートを生成する

## このリポジトリが検証する内容

現在のワークフローは、次のことを確認するためのものです。

- OpenSCAD でソースモデルが正常にレンダリングできる
- 生成された STL が設計パラメータと整合している
- PNG プレビューが生成される
- Bambu Studio CLI がヘッドレス Linux 環境で実行できる
- 最終的なスライサー出力が取得できる
- 実データから製造レポートが生成できる

これは「すべてのプリンター・素材・用途に対して安全である」と断言するものではなく、製造プロセスの再現性とレビュー性を担保するための検証です。

## リポジトリ管理された製造契約

現在のリポジトリには、以下の管理済みプロファイル契約があります。

- `profiles/machine/`
- `profiles/process/`
- `profiles/filament/`

これらのディレクトリは、Bambu スライスの挙動がホストデフォルトではなく、リポジトリ内で固定された設定に従うことを保証するために使われます。

## GitHub Actions

`.github/workflows/build-model.yml` は、ローカルで動いている Docker ベースのフローを GitHub 側でも同じ考え方で回すためのワークフローです。固定化された Linux ツールチェーンイメージを構築し、ツールチェーン契約を検証したうえで、同じビルドスクリプトをコンテナ内で実行します。

これは、ホスト依存のインストールを CI に混ぜ込むよりも、動作が確認済みの Linux の実行環境を再利用するための設計です。

## ローカル検証状況

このリポジトリでは、ローカルの Linux/Docker 環境で以下が確認済みです。

- OpenSCAD のレンダリング成功
- STL 生成成功
- PNG プレビュー生成成功
- Bambu CLI のヘッドレス実行成功
- 実スライサー出力から製造レポート生成成功

現在の優先事項は、ローカルでの E2E を安定させることです。CI を広げる前に、まずこの実行パスが壊れないように保つことが重要です。

## 制約と未解決事項

まだ物理的・製造的な検証が完了していない領域として、以下が明示的に扱われています。

- フィギュアの接地面積と質量許容範囲
- プリンターごとの肉厚要件
- インフィルや造形方向の前提条件
- 将来のアクセサリーや固定部品に必要な許容差

これらは推測ではなく、将来の検証対象として明示されます。

## 今後の方向性

次に有効な改善は段階的に行うべきです。

- 形状や寸法の自動妥当性チェックの強化
- プリンターや材料別の製造制約の追加
- クリアランスや公差の検証
- リリース向けメタデータと report の詳細化
- Pull Request での差分レビューとビジュアル確認の強化

## このリポジトリの使い方

1. リポジトリをクローンする
2. Linux ツールチェーンイメージをビルドする

```bash
docker buildx build --platform linux/amd64 --load -t hardware-devops-toolchain:bambu-studio toolchain/
```

3. コンテナ内で標準ビルドを実行する

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD:/workspace" \
  -w /workspace \
  hardware-devops-toolchain:bambu-studio \
  bash scripts/build-model.sh
```

4. `artifacts/` に生成された成果物と、`reports/` に生成されるレポートを確認する

5. 環境変数を設定して別寸法のモデルを生成する

```bash
STAND_WIDTH=100 STAND_DEPTH=80 STAND_HEIGHT=52 ./scripts/build-model.sh
```

このリポジトリは小さくても、ハードウェア PoC における設計、検証、生成、成果物保管、製造レポート生成の基本ループを示すための最小構成です。
